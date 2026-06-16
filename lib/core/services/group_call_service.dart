import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_token_generator/agora_token_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import 'call_service.dart' show CallType;

/// Statut d'un participant à un appel de groupe.
enum GroupCallParticipantStatus {
  invited,
  joined,
  left,
  rejected,
}

/// Données d'un participant à un appel de groupe.
@immutable
class GroupCallParticipant {
  final String id;
  final String memberId;
  final String name;
  final String? avatarUrl;
  final GroupCallParticipantStatus status;
  final DateTime? joinedAt;

  const GroupCallParticipant({
    required this.id,
    required this.memberId,
    required this.name,
    this.avatarUrl,
    this.status = GroupCallParticipantStatus.invited,
    this.joinedAt,
  });

  bool get isJoined => status == GroupCallParticipantStatus.joined;
}

/// Données d'un appel de groupe.
@immutable
class GroupCallData {
  final String groupCallId;
  final String conversationId;
  final String callerId;
  final String channelName;
  final CallType callType;
  final GroupCallStatus status;
  final DateTime? createdAt;

  const GroupCallData({
    required this.groupCallId,
    required this.conversationId,
    required this.callerId,
    required this.channelName,
    required this.callType,
    this.status = GroupCallStatus.pending,
    this.createdAt,
  });

  GroupCallData copyWith({
    GroupCallStatus? status,
  }) {
    return GroupCallData(
      groupCallId: groupCallId,
      conversationId: conversationId,
      callerId: callerId,
      channelName: channelName,
      callType: callType,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

enum GroupCallStatus { pending, active, ended, cancelled }

// CallType est défini dans call_service.dart — réutilisé ici pour éviter le conflit de nom.

/// Callbacks pour les événements d'appel de groupe.
class GroupCallCallbacks {
  final void Function(GroupCallData)? onIncomingCall;
  final void Function(GroupCallParticipant)? onParticipantJoined;
  final void Function(GroupCallParticipant)? onParticipantLeft;
  final void Function(GroupCallData)? onCallEnded;
  final void Function(String error)? onError;

  const GroupCallCallbacks({
    this.onIncomingCall,
    this.onParticipantJoined,
    this.onParticipantLeft,
    this.onCallEnded,
    this.onError,
  });
}

/// Service de gestion des appels de groupe (multi-participants) via Agora + Supabase.
///
/// Utilise Supabase Realtime sur `group_call_participants` pour la signalisation
/// et Agora RTC Engine pour le média temps réel.
class GroupCallService {
  GroupCallService._();
  static final GroupCallService _instance = GroupCallService._();
  static GroupCallService get instance => _instance;

  RtcEngine? _engine;
  RealtimeChannel? _signalingChannel;

  GroupCallData? _currentCall;
  GroupCallCallbacks? _callbacks;

  bool _isEngineInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOff = false;

  final ValueNotifier<List<int>> _remoteUids = ValueNotifier<List<int>>([]);
  final ValueNotifier<List<GroupCallParticipant>> _participants =
      ValueNotifier<List<GroupCallParticipant>>([]);

  /// UIDs distants des participants actuellement connectés.
  ValueListenable<List<int>> get remoteUids => _remoteUids;

  /// Participants de l'appel de groupe.
  ValueListenable<List<GroupCallParticipant>> get participants => _participants;

  // ── Public getters ─────────────────────────────────────────────────────

  GroupCallData? get currentCall => _currentCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isCameraOff => _isCameraOff;
  bool get hasActiveCall => _currentCall != null && _currentCall!.status != GroupCallStatus.ended;

  /// Accès public au moteur Agora.
  RtcEngine? get engine => _engine;

  // ── Engine lifecycle ───────────────────────────────────────────────────

  /// Initialise le moteur Agora.
  Future<void> initializeEngine() async {
    if (_isEngineInitialized) return;
    if (!AppConstants.hasAgoraConfig) {
      debugPrint('[GroupCallService] Agora non configuré — appels de groupe désactivés.');
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AppConstants.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _engine!.enableAudio();
      await _engine!.enableVideo();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('[Agora] Group call joined channel ${connection.channelId}');
        },
        onUserJoined: (connection, uid, elapsed) {
          debugPrint('[Agora] Group participant $uid joined');
          if (!_remoteUids.value.contains(uid)) {
            _remoteUids.value = [..._remoteUids.value, uid];
          }
        },
        onUserOffline: (connection, uid, reason) {
          debugPrint('[Agora] Group participant $uid offline: $reason');
          _remoteUids.value = _remoteUids.value.where((id) => id != uid).toList();
        },
        onLeaveChannel: (connection, stats) {
          debugPrint('[Agora] Group call left channel ${connection.channelId}');
          _remoteUids.value = [];
        },
        onError: (err, msg) {
          debugPrint('[Agora] Group call error: $err — $msg');
          _callbacks?.onError?.call('Erreur Agora: $msg');
        },
      ));

      _isEngineInitialized = true;
    } catch (e) {
      debugPrint('[GroupCallService] Erreur initialisation Agora: $e');
      throw ServerException("Impossible d'initialiser le moteur d'appel de groupe.", cause: e);
    }
  }

  /// Libère le moteur Agora.
  Future<void> disposeEngine() async {
    await _engine?.release();
    _engine = null;
    _isEngineInitialized = false;
    _remoteUids.value = [];
  }

  // ── Signaling (Supabase Realtime) ──────────────────────────────────────

  /// Démarre l'écoute des invitations d'appel de groupe.
  Future<void> startListening({
    required String memberId,
    GroupCallCallbacks? callbacks,
  }) async {
    await stopListening();
    _callbacks = callbacks;

    _signalingChannel = Supabase.instance.client
        .channel('group_call_participants_$memberId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_call_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'member_id',
            value: memberId,
          ),
          callback: (payload) {
            _handleParticipantChange(payload, memberId);
          },
        )
        .subscribe();
  }

  void _handleParticipantChange(PostgresChangePayload payload, String memberId) {
    final record = payload.newRecord;
    final groupCallId = record['group_call_id'] as String? ?? '';
    final participantStatus = record['status'] as String? ?? '';

    // Récupère les infos de l'appel de groupe
    _fetchGroupCall(groupCallId).then((callData) {
      if (callData == null) return;

      // Si on est invité et que l'appel est pending → incoming
      if (participantStatus == 'invited' &&
          callData.status == GroupCallStatus.pending &&
          callData.callerId != memberId) {
        _currentCall = callData;
        _callbacks?.onIncomingCall?.call(callData);
      }

      // Si un participant a rejoint
      if (participantStatus == 'joined') {
        _fetchParticipant(record['id'] as String).then((participant) {
          if (participant != null) {
            _updateParticipant(participant);
            _callbacks?.onParticipantJoined?.call(participant);
          }
        });
      }

      // Si un participant a quitté ou rejeté
      if (participantStatus == 'left' || participantStatus == 'rejected') {
        _fetchParticipant(record['id'] as String).then((participant) {
          if (participant != null) {
            _removeParticipant(participant.memberId);
            _callbacks?.onParticipantLeft?.call(participant);
          }
        });
      }

      // Si l'appel est terminé
      if (callData.status == GroupCallStatus.ended) {
        _currentCall = callData;
        _callbacks?.onCallEnded?.call(callData);
        _endCallLocal();
      }
    }).catchError((e) {
      debugPrint('[GroupCallService] Erreur traitement changement: $e');
    });
  }

  Future<GroupCallData?> _fetchGroupCall(String groupCallId) async {
    try {
      final response = await Supabase.instance.client
          .from('group_calls')
          .select()
          .eq('id', groupCallId)
          .maybeSingle();

      if (response == null) return null;

      return GroupCallData(
        groupCallId: response['id'] as String,
        conversationId: response['conversation_id'] as String,
        callerId: response['caller_id'] as String,
        channelName: response['agora_channel'] as String,
        callType: response['call_type'] == 'video' ? CallType.video : CallType.audio,
        status: _groupStatusFromString(response['status'] as String),
        createdAt: DateTime.tryParse(response['created_at'] as String? ?? ''),
      );
    } catch (e) {
      debugPrint('[GroupCallService] Erreur fetch group call: $e');
      return null;
    }
  }

  Future<GroupCallParticipant?> _fetchParticipant(String participantId) async {
    try {
      final response = await Supabase.instance.client
          .from('group_call_participants')
          .select('*, member:member_id(name, avatar_url)')
          .eq('id', participantId)
          .maybeSingle();

      if (response == null) return null;

      final member = response['member'] as Map<String, dynamic>?;
      return GroupCallParticipant(
        id: response['id'] as String,
        memberId: response['member_id'] as String,
        name: member?['name'] as String? ?? 'Participant',
        avatarUrl: member?['avatar_url'] as String?,
        status: _participantStatusFromString(response['status'] as String),
        joinedAt: DateTime.tryParse(response['joined_at'] as String? ?? ''),
      );
    } catch (e) {
      debugPrint('[GroupCallService] Erreur fetch participant: $e');
      return null;
    }
  }

  void _updateParticipant(GroupCallParticipant participant) {
    final current = _participants.value;
    final index = current.indexWhere((p) => p.memberId == participant.memberId);
    if (index >= 0) {
      final updated = [...current];
      updated[index] = participant;
      _participants.value = updated;
    } else {
      _participants.value = [...current, participant];
    }
  }

  void _removeParticipant(String memberId) {
    _participants.value = _participants.value.where((p) => p.memberId != memberId).toList();
  }

  GroupCallStatus _groupStatusFromString(String status) {
    switch (status) {
      case 'pending': return GroupCallStatus.pending;
      case 'active': return GroupCallStatus.active;
      case 'ended': return GroupCallStatus.ended;
      case 'cancelled': return GroupCallStatus.cancelled;
      default: return GroupCallStatus.pending;
    }
  }

  GroupCallParticipantStatus _participantStatusFromString(String status) {
    switch (status) {
      case 'invited': return GroupCallParticipantStatus.invited;
      case 'joined': return GroupCallParticipantStatus.joined;
      case 'left': return GroupCallParticipantStatus.left;
      case 'rejected': return GroupCallParticipantStatus.rejected;
      default: return GroupCallParticipantStatus.invited;
    }
  }

  /// Arrête l'écoute des invitations.
  Future<void> stopListening() async {
    await _signalingChannel?.unsubscribe();
    _signalingChannel = null;
    _callbacks = null;
  }

  // ── Call actions ─────────────────────────────────────────────────────────

  /// Démarre un appel de groupe.
  Future<GroupCallData> startGroupCall({
    required String callerMemberId,
    required String conversationId,
    required CallType callType,
    required List<String> participantMemberIds,
  }) async {
    if (!AppConstants.hasAgoraConfig) {
      throw const ServerException('Agora non configuré. Les appels de groupe sont désactivés.');
    }
    if (hasActiveCall) {
      throw const ServerException('Un appel est déjà en cours.');
    }

    final channelName = 'group_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    try {
      // Crée l'appel de groupe
      final response = await Supabase.instance.client
          .from('group_calls')
          .insert({
            'caller_id': callerMemberId,
            'conversation_id': conversationId,
            'call_type': callType == CallType.video ? 'video' : 'audio',
            'status': 'pending',
            'agora_channel': channelName,
          })
          .select()
          .single();

      final groupCallId = response['id'] as String;

      // Invite tous les participants
      final now = DateTime.now().toUtc().toIso8601String();
      final invitations = participantMemberIds
          .where((id) => id != callerMemberId)
          .map((memberId) => {
                'group_call_id': groupCallId,
                'member_id': memberId,
                'status': 'invited',
                'invited_at': now,
              })
          .toList();

      if (invitations.isNotEmpty) {
        await Supabase.instance.client.from('group_call_participants').insert(invitations);
      }

      // Ajoute le caller comme participant
      await Supabase.instance.client.from('group_call_participants').insert({
        'group_call_id': groupCallId,
        'member_id': callerMemberId,
        'status': 'joined',
        'invited_at': now,
        'joined_at': now,
      });

      final callData = GroupCallData(
        groupCallId: groupCallId,
        conversationId: conversationId,
        callerId: callerMemberId,
        channelName: channelName,
        callType: callType,
        status: GroupCallStatus.pending,
        createdAt: DateTime.now(),
      );

      _currentCall = callData;
      await _joinChannel(channelName, callType);

      return callData;
    } catch (e) {
      _currentCall = null;
      throw ServerException("Impossible de démarrer l'appel de groupe.", cause: e);
    }
  }

  /// Accepte un appel de groupe (le participant rejoint).
  Future<void> acceptGroupCall(GroupCallData callData) async {
    try {
      final memberId = Supabase.instance.client.auth.currentUser?.id;
      if (memberId == null) {
        throw const AuthException('Utilisateur non authentifié.');
      }

      // Résout members.id
      final memberRows = await Supabase.instance.client
          .from('members')
          .select('id')
          .eq('user_id', memberId)
          .maybeSingle();
      if (memberRows == null) {
        throw const AuthException('Profil membre introuvable.');
      }
      final currentMemberId = memberRows['id'] as String;

      // Met à jour le statut du participant
      await Supabase.instance.client
          .from('group_call_participants')
          .update({
            'status': 'joined',
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('group_call_id', callData.groupCallId)
          .eq('member_id', currentMemberId);

      // Active l'appel si c'est le premier à rejoindre
      await Supabase.instance.client
          .from('group_calls')
          .update({'status': 'active'})
          .eq('id', callData.groupCallId);

      await _joinChannel(callData.channelName, callData.callType);
      _currentCall = callData.copyWith(status: GroupCallStatus.active);
    } catch (e) {
      throw ServerException("Impossible de rejoindre l'appel de groupe.", cause: e);
    }
  }

  /// Quitte un appel de groupe.
  Future<void> leaveGroupCall() async {
    if (_currentCall == null) return;

    try {
      final memberId = Supabase.instance.client.auth.currentUser?.id;
      if (memberId != null) {
        final memberRows = await Supabase.instance.client
            .from('members')
            .select('id')
            .eq('user_id', memberId)
            .maybeSingle();
        if (memberRows != null) {
          final currentMemberId = memberRows['id'] as String;
          await Supabase.instance.client
              .from('group_call_participants')
              .update({
                'status': 'left',
                'left_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('group_call_id', _currentCall!.groupCallId)
              .eq('member_id', currentMemberId);
        }
      }

      await _leaveChannel();
      _currentCall = null;
      _participants.value = [];
      _remoteUids.value = [];
    } catch (e) {
      throw ServerException('Impossible de quitter l\'appel de groupe.', cause: e);
    }
  }

  /// Rejette un appel de groupe entrant.
  Future<void> rejectGroupCall(GroupCallData callData) async {
    try {
      final memberId = Supabase.instance.client.auth.currentUser?.id;
      if (memberId == null) return;

      final memberRows = await Supabase.instance.client
          .from('members')
          .select('id')
          .eq('user_id', memberId)
          .maybeSingle();
      if (memberRows == null) return;
      final currentMemberId = memberRows['id'] as String;

      await Supabase.instance.client
          .from('group_call_participants')
          .update({
            'status': 'rejected',
            'left_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('group_call_id', callData.groupCallId)
          .eq('member_id', currentMemberId);

      _currentCall = null;
    } catch (e) {
      throw ServerException('Impossible de rejeter l\'appel de groupe.', cause: e);
    }
  }

  /// Annule un appel de groupe sortant (caller uniquement).
  Future<void> cancelGroupCall(GroupCallData callData) async {
    try {
      await Supabase.instance.client
          .from('group_calls')
          .update({
            'status': 'cancelled',
            'ended_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', callData.groupCallId);

      // Insère un message système dans la conversation
      await _insertGroupCallMessage(
        conversationId: callData.conversationId,
        callType: callData.callType,
        callStatus: 'cancelled',
        callerId: callData.callerId,
      );

      await _leaveChannel();
      _currentCall = null;
      _participants.value = [];
      _remoteUids.value = [];
    } catch (e) {
      throw ServerException('Impossible d\'annuler l\'appel de groupe.', cause: e);
    }
  }

  /// Termine l'appel de groupe (caller uniquement).
  Future<void> endGroupCall() async {
    if (_currentCall == null) return;

    final call = _currentCall!;
    final now = DateTime.now().toUtc();
    final startedAt = call.createdAt;
    final duration = startedAt != null ? now.difference(startedAt) : null;

    try {
      await Supabase.instance.client
          .from('group_calls')
          .update({
            'status': 'ended',
            'ended_at': now.toIso8601String(),
          })
          .eq('id', call.groupCallId);

      // Insère un message système dans la conversation
      await _insertGroupCallMessage(
        conversationId: call.conversationId,
        callType: call.callType,
        callStatus: 'ended',
        callerId: call.callerId,
        duration: duration,
      );

      await _leaveChannel();
      _currentCall = null;
      _participants.value = [];
      _remoteUids.value = [];
    } catch (e) {
      throw ServerException('Impossible de terminer l\'appel de groupe.', cause: e);
    }
  }

  void _endCallLocal() {
    _leaveChannel();
    _currentCall = null;
    _participants.value = [];
    _remoteUids.value = [];
  }

  /// Insère un message système dans la conversation pour tracer l'appel de groupe.
  Future<void> _insertGroupCallMessage({
    required String conversationId,
    required CallType callType,
    required String callStatus,
    required String callerId,
    Duration? duration,
  }) async {
    try {
      final durStr = duration != null
          ? '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}'
          : null;

      await Supabase.instance.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': callerId,
        'content': '',
        'metadata': {
          'msg_type': 'call',
          'call_type': callType == CallType.video ? 'video' : 'audio',
          'call_status': callStatus,
          'is_group': true,
          if (durStr != null) 'duration': durStr,
          'caller_id': callerId,
        },
      });
    } catch (e) {
      debugPrint('[GroupCallService] Erreur insertion message appel: $e');
    }
  }

  // ── Agora channel management ───────────────────────────────────────────

  Future<void> _joinChannel(String channelName, CallType callType) async {
    if (_engine == null) {
      await initializeEngine();
    }

    await _engine!.joinChannel(
      token: _buildToken(channelName),
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    if (callType == CallType.video) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.disableVideo();
    }
  }

  Future<void> _leaveChannel() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.stopPreview();
    } catch (_) {}
    _isMuted = false;
    _isSpeakerOn = false;
    _isCameraOff = false;
  }

  // ── In-call controls ───────────────────────────────────────────────────

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> toggleCamera() async {
    if (_currentCall?.callType != CallType.video) return;
    _isCameraOff = !_isCameraOff;
    await _engine?.muteLocalVideoStream(_isCameraOff);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Construit un token Agora pour le canal donné.
  ///
  /// Si `AGORA_APP_CERTIFICATE` est configuré, génère un token HMAC-SHA256
  /// valide 24h. Sinon, retourne une chaîne vide (nécessite que le
  /// App Certificate soit désactivé dans la console Agora).
  String _buildToken(String channelName) {
    if (!AppConstants.hasAgoraCertificateConfig) {
      return '';
    }
    try {
      return RtcTokenBuilder.buildTokenWithUid(
        appId: AppConstants.agoraAppId,
        appCertificate: AppConstants.agoraAppCertificate,
        channelName: channelName,
        uid: 0,
        tokenExpireSeconds: 86400, // 24h
      );
    } catch (e) {
      debugPrint('[GroupCallService] Erreur génération token Agora: $e');
      return '';
    }
  }

  /// Widget pour afficher la vidéo locale.
  Widget localVideoView() {
    if (_engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  /// Widget pour afficher la vidéo d'un participant distant.
  Widget remoteVideoView(int remoteUid) {
    if (_engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: _currentCall?.channelName ?? ''),
      ),
    );
  }
}

/// AuthException minimal pour les cas d'erreur.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}
