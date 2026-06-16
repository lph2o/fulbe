import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_token_generator/agora_token_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Statut d'un appel.
enum CallStatus {
  idle,
  calling,
  ringing,
  connected,
  ended,
  rejected,
  missed,
}

/// Données d'un appel en cours.
class CallData {
  final String callInviteId;
  final String channelName;
  final String callerId;
  final String calleeId;
  final String conversationId;
  final CallType callType;
  final CallStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const CallData({
    required this.callInviteId,
    required this.channelName,
    required this.callerId,
    required this.calleeId,
    required this.conversationId,
    required this.callType,
    this.status = CallStatus.idle,
    this.startedAt,
    this.endedAt,
  });

  CallData copyWith({
    CallStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return CallData(
      callInviteId: callInviteId,
      channelName: channelName,
      callerId: callerId,
      calleeId: calleeId,
      conversationId: conversationId,
      callType: callType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  bool get isOutgoing => callerId == Supabase.instance.client.auth.currentUser?.id;
  bool get isIncoming => calleeId == Supabase.instance.client.auth.currentUser?.id;
}

enum CallType { audio, video }

/// Callbacks pour les événements d'appel.
class CallCallbacks {
  final void Function(CallData)? onIncomingCall;
  final void Function(CallData)? onCallAccepted;
  final void Function(CallData)? onCallRejected;
  final void Function(CallData)? onCallEnded;
  final void Function(CallData)? onCallCancelled;
  final void Function(String error)? onError;

  const CallCallbacks({
    this.onIncomingCall,
    this.onCallAccepted,
    this.onCallRejected,
    this.onCallEnded,
    this.onCallCancelled,
    this.onError,
  });
}

/// Service de gestion des appels audio/vidéo 1-to-1 via Agora + Supabase.
///
/// Utilise Supabase Realtime pour la signalisation (call_invites) et
/// Agora RTC Engine pour le média temps réel.
class CallService {
  CallService._();
  static final CallService _instance = CallService._();
  static CallService get instance => _instance;

  RtcEngine? _engine;
  RealtimeChannel? _signalingChannel;
  RealtimeChannel? _callerSignalingChannel;

  CallData? _currentCall;
  CallCallbacks? _callbacks;

  bool _isEngineInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOff = false;

  final ValueNotifier<int?> _remoteUid = ValueNotifier<int?>(null);

  /// UID distant de l'appel en cours (null si personne n'a rejoint).
  ValueListenable<int?> get remoteUid => _remoteUid;

  // ── Public getters ─────────────────────────────────────────────────────

  CallData? get currentCall => _currentCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isCameraOff => _isCameraOff;
  bool get hasActiveCall => _currentCall != null && _currentCall!.status != CallStatus.ended && _currentCall!.status != CallStatus.idle;

  /// Accès public au moteur Agora (pour les écrans d'appel).
  RtcEngine? get engine => _engine;

  // ── Engine lifecycle ───────────────────────────────────────────────────

  /// Initialise le moteur Agora (à appeler une fois au démarrage de l'app).
  Future<void> initializeEngine() async {
    if (_isEngineInitialized) return;
    if (!AppConstants.hasAgoraConfig) {
      debugPrint('[CallService] Agora non configuré — appels désactivés.');
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

      // Écoute les événements Agora
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('[Agora] Joined channel ${connection.channelId}');
        },
        onUserJoined: (connection, uid, elapsed) {
          debugPrint('[Agora] Remote user $uid joined');
          _remoteUid.value = uid;
          if (_currentCall != null) {
            _currentCall = _currentCall!.copyWith(status: CallStatus.connected);
          }
        },
        onUserOffline: (connection, uid, reason) {
          debugPrint('[Agora] Remote user $uid offline: $reason');
          _remoteUid.value = null;
          endCall();
        },
        onLeaveChannel: (connection, stats) {
          debugPrint('[Agora] Left channel ${connection.channelId}');
        },
        onError: (err, msg) {
          debugPrint('[Agora] Error $err: $msg');
          final hint = _agoraErrorHint(err);
          _callbacks?.onError?.call(
            'Erreur Agora ($err) : $msg${hint != null ? '\n$hint' : ''}',
          );
        },
      ));

      _isEngineInitialized = true;
    } catch (e) {
      debugPrint('[CallService] Erreur initialisation Agora: $e');
      throw ServerException('Impossible d\'initialiser le moteur d\'appel.', cause: e);
    }
  }

  /// Libère le moteur Agora.
  Future<void> disposeEngine() async {
    await _engine?.release();
    _engine = null;
    _isEngineInitialized = false;
    _remoteUid.value = null;
  }

  // ── Signaling (Supabase Realtime) ──────────────────────────────────────

  /// Démarre l'écoute des invitations d'appel pour l'utilisateur courant.
  ///
  /// [onIncomingCall] est déclenché quand quelqu'un nous appelle.
  /// [onCallAccepted] est déclenché quand l'appelé accepte.
  /// [onCallRejected] est déclenché quand l'appelé refuse.
  Future<void> startListening({
    required String memberId,
    CallCallbacks? callbacks,
  }) async {
    // Nettoie les écouteurs précédents pour éviter les fuites de canaux.
    await stopListening();
    _callbacks = callbacks;

    // Écoute les changements sur la table call_invites
    _signalingChannel = Supabase.instance.client
        .channel('call_invites_$memberId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'call_invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'callee_id',
            value: memberId,
          ),
          callback: (payload) {
            _handleCallInviteChange(payload, memberId);
          },
        )
        .subscribe();

    // Écoute aussi les changements où on est l'appelant (pour savoir
    // si l'appelé a accepté/rejeté).
    _callerSignalingChannel = Supabase.instance.client
        .channel('call_invites_caller_$memberId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'call_invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'caller_id',
            value: memberId,
          ),
          callback: (payload) {
            _handleCallInviteChange(payload, memberId);
          },
        )
        .subscribe();
  }

  void _handleCallInviteChange(PostgresChangePayload payload, String memberId) {
    final record = payload.newRecord;
    final callInviteId = record['id'] as String? ?? '';
    final status = record['status'] as String? ?? 'pending';
    final callType = record['call_type'] as String? ?? 'audio';
    final channelName = record['agora_channel'] as String? ?? '';
    final callerId = record['caller_id'] as String? ?? '';
    final calleeId = record['callee_id'] as String? ?? '';
    final conversationId = record['conversation_id'] as String? ?? '';

    final data = CallData(
      callInviteId: callInviteId,
      channelName: channelName,
      callerId: callerId,
      calleeId: calleeId,
      conversationId: conversationId,
      callType: callType == 'video' ? CallType.video : CallType.audio,
      status: _statusFromString(status),
    );

    // Si on est l'appelé et que l'appel est pending → incoming
    if (calleeId == memberId && status == 'pending') {
      _currentCall = data;
      _callbacks?.onIncomingCall?.call(data);
    }
    // Si on est l'appelant et que l'appelé a accepté
    else if (callerId == memberId && status == 'accepted') {
      final startedAtStr = record['started_at'] as String?;
      final startedAt = startedAtStr != null ? DateTime.tryParse(startedAtStr) : null;
      _currentCall = data.copyWith(
        status: CallStatus.connected,
        startedAt: startedAt,
      );
      _callbacks?.onCallAccepted?.call(_currentCall!);
    }
    // Si on est l'appelant et que l'appelé a rejeté
    else if (callerId == memberId && status == 'rejected') {
      _currentCall = data.copyWith(status: CallStatus.rejected);
      _callbacks?.onCallRejected?.call(_currentCall!);
      _currentCall = null;
    }
    // Si l'appel est terminé (par n'importe qui)
    else if (status == 'ended') {
      _currentCall = data.copyWith(status: CallStatus.ended);
      _callbacks?.onCallEnded?.call(_currentCall!);
      // Le message système est inséré par endCall() côté caller.
      _endCallLocal();
    }
    // Si l'appelant a annulé
    else if (status == 'cancelled' && calleeId == memberId) {
      _currentCall = data.copyWith(status: CallStatus.ended);
      _callbacks?.onCallCancelled?.call(_currentCall!);
      // Le message système est inséré par cancelCall() côté caller.
      _currentCall = null;
    }
    // Si l'appel est marqué comme manqué (timeout côté serveur)
    else if (status == 'missed' && calleeId == memberId) {
      // Le message système est inséré par la fonction SQL
      // mark_stale_calls_missed() exécutée périodiquement.
      _callbacks?.onCallCancelled?.call(data.copyWith(status: CallStatus.missed));
    }
  }

  CallStatus _statusFromString(String status) {
    switch (status) {
      case 'pending': return CallStatus.ringing;
      case 'accepted': return CallStatus.connected;
      case 'rejected': return CallStatus.rejected;
      case 'ended': return CallStatus.ended;
      case 'missed': return CallStatus.missed;
      case 'cancelled': return CallStatus.ended;
      default: return CallStatus.idle;
    }
  }

  /// Arrête l'écoute des invitations.
  Future<void> stopListening() async {
    await _signalingChannel?.unsubscribe();
    await _callerSignalingChannel?.unsubscribe();
    _signalingChannel = null;
    _callerSignalingChannel = null;
    _callbacks = null;
  }

  // ── Call actions ─────────────────────────────────────────────────────────

  /// Démarre un appel sortant.
  ///
  /// Crée une ligne `call_invites` avec status `pending`, puis rejoint
  /// le canal Agora en attendant que l'appelé accepte.
  Future<CallData> startCall({
    required String callerMemberId,
    required String calleeMemberId,
    required String conversationId,
    required CallType callType,
  }) async {
    if (!AppConstants.hasAgoraConfig) {
      throw const ServerException(
        'Agora non configuré. Les appels sont désactivés.',
      );
    }
    if (_currentCall != null && _currentCall!.status != CallStatus.ended) {
      throw const ServerException(
        'Un appel est déjà en cours.',
      );
    }

    final channelName = 'call_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    try {
      // Insère l'invitation dans Supabase
      final response = await Supabase.instance.client
          .from('call_invites')
          .insert({
            'caller_id': callerMemberId,
            'callee_id': calleeMemberId,
            'conversation_id': conversationId,
            'call_type': callType == CallType.video ? 'video' : 'audio',
            'status': 'pending',
            'agora_channel': channelName,
          })
          .select()
          .single();

      final callInviteId = response['id'] as String;

      final callData = CallData(
        callInviteId: callInviteId,
        channelName: channelName,
        callerId: callerMemberId,
        calleeId: calleeMemberId,
        conversationId: conversationId,
        callType: callType,
        status: CallStatus.calling,
      );

      _currentCall = callData;

      // Rejoint le canal Agora (en dev, token = null)
      await _joinChannel(channelName);

      return callData;
    } catch (e) {
      _currentCall = null;
      throw ServerException(
        "Impossible de démarrer l'appel.",
        cause: e,
      );
    }
  }

  /// Accepte un appel entrant.
  Future<void> acceptCall(CallData callData) async {
    try {
      final now = DateTime.now().toUtc();
      await Supabase.instance.client
          .from('call_invites')
          .update({'status': 'accepted', 'started_at': now.toIso8601String()})
          .eq('id', callData.callInviteId);

      await _joinChannel(callData.channelName);

      _currentCall = callData.copyWith(
        status: CallStatus.connected,
        startedAt: now,
      );
    } catch (e) {
      throw ServerException("Impossible d'accepter l'appel.", cause: e);
    }
  }

  /// Rejette un appel entrant.
  Future<void> rejectCall(CallData callData) async {
    try {
      await Supabase.instance.client
          .from('call_invites')
          .update({'status': 'rejected'})
          .eq('id', callData.callInviteId);

      // Insère un message "Appel refusé" dans la conversation
      await _insertCallMessage(
        conversationId: callData.conversationId,
        callType: callData.callType,
        callStatus: 'rejected',
        callerId: callData.callerId,
        calleeId: callData.calleeId,
      );

      await _leaveChannel();
      _currentCall = null;
    } catch (e) {
      throw ServerException('Impossible de rejeter l\'appel.', cause: e);
    }
  }

  /// Annule un appel sortant (avant que l'appelé ne réponde).
  Future<void> cancelCall() async {
    if (_currentCall == null) return;

    final call = _currentCall!;
    try {
      await Supabase.instance.client
          .from('call_invites')
          .update({'status': 'cancelled'})
          .eq('id', call.callInviteId);

      // Insère un message "Appel annulé" (visible par le destinataire comme appel manqué)
      await _insertCallMessage(
        conversationId: call.conversationId,
        callType: call.callType,
        callStatus: 'cancelled',
        callerId: call.callerId,
        calleeId: call.calleeId,
      );

      await _leaveChannel();
      _currentCall = null;
    } catch (e) {
      throw ServerException('Impossible d\'annuler l\'appel.', cause: e);
    }
  }

  /// Termine un appel en cours.
  Future<void> endCall() async {
    if (_currentCall == null) return;

    final call = _currentCall!;
    final now = DateTime.now().toUtc();
    final startedAt = call.startedAt;
    final duration = startedAt != null
        ? now.difference(startedAt)
        : null;

    try {
      await Supabase.instance.client
          .from('call_invites')
          .update({
            'status': 'ended',
            'ended_at': now.toIso8601String(),
          })
          .eq('id', call.callInviteId);

      // Insère un message système dans la conversation
      await _insertCallMessage(
        conversationId: call.conversationId,
        callType: call.callType,
        callStatus: 'ended',
        duration: duration,
        callerId: call.callerId,
        calleeId: call.calleeId,
      );

      await _leaveChannel();
      _currentCall = null;
    } catch (e) {
      throw ServerException('Impossible de terminer l\'appel.', cause: e);
    }
  }

  void _endCallLocal() {
    _leaveChannel();
    _currentCall = null;
    _remoteUid.value = null;
  }

  /// Insère un message système dans la conversation pour tracer l'appel.
  Future<void> _insertCallMessage({
    required String conversationId,
    required CallType callType,
    required String callStatus,
    required String callerId,
    required String calleeId,
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
          if (durStr != null) 'duration': durStr,
          'caller_id': callerId,
          'callee_id': calleeId,
        },
      });
    } catch (e) {
      debugPrint('[CallService] Erreur insertion message appel: $e');
    }
  }

  // ── Agora channel management ───────────────────────────────────────────

  Future<void> _joinChannel(String channelName) async {
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

    // Active la vidéo seulement si c'est un appel vidéo
    if (_currentCall?.callType == CallType.video) {
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
    } catch (_) {
      // Ignorer les erreurs de leaveChannel
    }
    _isMuted = false;
    _isSpeakerOn = false;
    _isCameraOff = false;
  }

  /// Fournit une suggestion de résolution selon le code d'erreur Agora.
  String? _agoraErrorHint(ErrorCodeType errorCode) {
    // Certaines erreurs Agora sont remontées en négatif.
    final absCode = errorCode.index;
    switch (absCode) {
      case 101: // ERR_INVALID_APP_ID
        return "Vérifiez l'AGORA_APP_ID dans votre fichier .env.";
      case 17: // ERR_JOIN_CHANNEL_REJECTED
        return 'Dans la console Agora, désactivez le certificat (App Certificate) '
            'ou générez un token avec AGORA_APP_CERTIFICATE.';
      case 7: // ERR_NOT_INITIALIZED
        return 'Le moteur Agora n\'a pas pu démarrer. Redémarrez l\'application.';
      default:
        // errInvalidToken (code 2 dans l'enum Agora) et autres
        if (errorCode == ErrorCodeType.errInvalidToken) {
          return 'Token Agora invalide. Vérifiez que le App Certificate est '
              'désactivé dans la console Agora (mode dev), ou configurez '
              'AGORA_APP_CERTIFICATE dans votre .env.';
        }
        return null;
    }
  }

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
      debugPrint('[CallService] Erreur génération token Agora: $e');
      return '';
    }
  }

  /// Widget pour afficher la vidéo distante.
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
