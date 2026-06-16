import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/data/models/conversation.dart';
import '../../core/data/models/member.dart';
import '../../core/data/models/conversation.dart' show ChatMessage;
import '../../core/data/providers/data_providers.dart';
import '../../core/data/repositories/conversations_repository.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/call_service.dart';
import '../../core/services/group_call_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/navigation/app_router.dart';
import '../../shared/widgets/voice_message_bubble.dart';
import '../../shared/widgets/voice_recorder_bar.dart';

/// Écran de conversation (chat 1-to-1 ou groupe).
class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final _repo = const ConversationsRepository();
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _audioRecorder = AudioRecorder();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isCallActive = false;
  bool _isGroup = false;
  List<Member> _allParticipants = [];

  // ── État de l'enregistrement vocal ────────────────────────────────
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _elapsed = Duration.zero;
  bool _isUploading = false;
  Timer? _recordingTimer;
  String? _recordingPath;

  RealtimeChannel? _messagesChannel;

  Member? _otherParticipant;

  @override
  void initState() {
    super.initState();
    _loadConversationInfo();
    _loadMessages();
    _listenToMessages();
    _preInitAgora();
    _initializeCallService();
    _initializeGroupCallService();
    _cacheOtherParticipant();
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    CallService.instance.stopListening();
    GroupCallService.instance.stopListening();
    super.dispose();
  }

  Future<void> _loadConversationInfo() async {
    try {
      final rows = await _repo.getAllParticipants(widget.conversationId);
      if (rows.isEmpty) return;

      final currentMember = ref.read(currentMemberProvider);
      final current = currentMember.asData?.value;
      if (current == null) return;

      // Détecte si c'est un groupe (plus de 2 participants)
      final isGroup = rows.length > 2;
      final other = rows.where((m) => m.id != current.id).toList();

      if (mounted) {
        setState(() {
          _isGroup = isGroup;
          _allParticipants = rows;
          if (!isGroup && other.isNotEmpty) {
            _otherParticipant = other.first;
          }
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _cacheOtherParticipant() async {
    final currentMember = ref.read(currentMemberProvider);
    final member = currentMember.asData?.value;
    if (member == null) return;
    final other = await _repo.findOtherParticipant(
      widget.conversationId,
      member.id,
    );
    if (mounted) {
      setState(() => _otherParticipant = other);
    }
  }

  // ── Load messages ──────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    try {
      final msgs = await _repo.fetchMessages(widget.conversationId);
      if (mounted) {
        final currentMember = ref.read(currentMemberProvider).asData?.value;
        final myId = currentMember?.id;
        setState(() {
          _messages = msgs
              .map((m) => m.copyWith(
                    isMine: myId != null && m.senderId == myId,
                  ))
              .toList(growable: false);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Realtime listeners ───────────────────────────────────────────────

  void _listenToMessages() {
    _messagesChannel = Supabase.instance.client
        .channel('messages_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            var msg = ChatMessage.fromJson(record);
            final currentMember = ref.read(currentMemberProvider).asData?.value;
            if (currentMember != null && msg.senderId == currentMember.id) {
              msg = msg.copyWith(isMine: true);
            }
            if (mounted) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  // ── Scroll helpers ─────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Voice recording ─────────────────────────────────────────────────

  Future<bool> _startVoiceRecording() async {
    // 1. Vérifie la permission micro
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        if (status == PermissionStatus.permanentlyDenied) {
          _showMicrophonePermanentlyDeniedDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission microphone requise.')),
          );
        }
      }
      return false;
    }

    // 2. Vérifie qu'aucun autre enregistrement n'est en cours
    if (await _audioRecorder.isRecording()) return false;

    try {
      // 3. Démarre l'enregistrement dans le dossier temporaire
      final dir = Directory.systemTemp;
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = '${dir.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordingPath = path;

      // 4. Lance le timer de durée
      _elapsed = Duration.zero;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) {
          setState(() => _elapsed += const Duration(milliseconds: 100));
        }
      });

      if (mounted) {
        setState(() {
          _isRecording = true;
          _isPaused = false;
        });
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur microphone : $e')),
        );
      }
      return false;
    }
  }

  Future<void> _togglePauseRecording() async {
    try {
      if (_isPaused) {
        await _audioRecorder.resume();
        _recordingTimer = Timer.periodic(
            const Duration(milliseconds: 100),
            (_) {
              if (mounted) setState(() => _elapsed += const Duration(milliseconds: 100));
            });
      } else {
        await _audioRecorder.pause();
        _recordingTimer?.cancel();
      }
      if (mounted) setState(() => _isPaused = !_isPaused);
    } catch (_) {}
  }

  Future<void> _cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    // Supprime le fichier temporaire
    if (_recordingPath != null) {
      try {
        await File(_recordingPath!).delete();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _elapsed = Duration.zero;
        _recordingPath = null;
      });
    }
  }

  Future<void> _deleteVoiceRecording() async {
    _recordingTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    if (_recordingPath != null) {
      try {
        await File(_recordingPath!).delete();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _elapsed = Duration.zero;
        _recordingPath = null;
      });
    }
  }

  Future<void> _lockVoiceRecording() async {
    // Déjà en train d'enregistrer, on verrouille simplement l'état.
    // Le VoiceRecorderBar passe en mode "locked" et affiche pause/send/delete.
    // Pas d'action supplémentaire nécessaire côté parent.
  }

  Future<void> _sendVoiceRecording() async {
    _recordingTimer?.cancel();

    // Arrête l'enregistrement
    String? filePath;
    try {
      filePath = await _audioRecorder.stop();
    } catch (_) {}

    final finalPath = filePath ?? _recordingPath;
    final duration = _elapsed;

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _elapsed = Duration.zero;
        _isUploading = true;
        _recordingPath = null;
      });
    }

    // Vérifie la durée minimale (300ms)
    if (duration.inMilliseconds < 300 || finalPath == null) {
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    try {
      await _uploadAndSendVoice(finalPath, duration);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'envoi du message vocal : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadAndSendVoice(String filePath, Duration duration) async {
    final currentMember = ref.read(currentMemberProvider).asData?.value;
    if (currentMember == null) return;

    final file = File(filePath);
    final fileName =
        'voice/${currentMember.id}/${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Upload vers Supabase Storage (bucket "attachments")
    await Supabase.instance.client.storage
        .from('attachments')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: false));

    // Récupère l'URL publique
    final publicUrl = Supabase.instance.client.storage
        .from('attachments')
        .getPublicUrl(fileName);

    // Calcule les amplitudes pour la waveform (simplifié : aléatoire déterministe)
    final waveform = List.generate(32, (i) {
      final seed = (fileName.hashCode + i * 7) % 100;
      return 0.3 + (seed / 100) * 0.7;
    });

    // Durée formatée "mm:ss"
    final durStr =
        '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    // Envoie le message avec metadata
    await _repo.sendMessage(
      conversationId: widget.conversationId,
      senderMemberId: currentMember.id,
      content: publicUrl,
      metadata: {
        'msg_type': 'audio',
        'duration': durStr,
        'file_url': publicUrl,
        'waveform': waveform,
      },
    );

    // Nettoie le fichier temporaire
    try {
      await file.delete();
    } catch (_) {}
  }

  // ── Send message ───────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _focusNode.requestFocus();

    final currentMember = ref.read(currentMemberProvider);
    final member = currentMember.asData?.value;
    if (member == null) return;

    try {
      await _repo.sendMessage(
        conversationId: widget.conversationId,
        senderMemberId: member.id,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'envoyer le message.')),
        );
      }
    }
  }

  // ── Call integration ───────────────────────────────────────────────────

  /// Pré-initialise le moteur Agora pour détecter les erreurs tôt.
  Future<void> _preInitAgora() async {
    try {
      await CallService.instance.initializeEngine();
    } catch (_) {
      // L'erreur sera remontée quand l'utilisateur appuiera sur le bouton d'appel.
    }
  }

  void _initializeCallService() {
    final currentMemberAsync = ref.read(currentMemberProvider);
    if (currentMemberAsync is AsyncData<Member?>) {
      final member = currentMemberAsync.value;
      if (member != null) {
        CallService.instance.startListening(
          memberId: member.id,
          callbacks: CallCallbacks(
            onIncomingCall: _handleIncomingCall,
            onCallAccepted: _handleCallAccepted,
            onCallRejected: _handleCallRejected,
            onCallEnded: _handleCallEnded,
            onCallCancelled: _handleCallCancelled,
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
          ),
        );
      }
    }
  }

  void _initializeGroupCallService() {
    final currentMemberAsync = ref.read(currentMemberProvider);
    if (currentMemberAsync is AsyncData<Member?>) {
      final member = currentMemberAsync.value;
      if (member != null) {
        GroupCallService.instance.startListening(
          memberId: member.id,
          callbacks: GroupCallCallbacks(
            onIncomingCall: _handleGroupIncomingCall,
            onCallEnded: _handleGroupCallEnded,
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
          ),
        );
      }
    }
  }

  // Notification callback est assigné globalement dans main.dart.
  // Pas besoin de le dupliquer ici.

  void _handleIncomingCall(CallData callData) {
    if (_isCallActive) {
      CallService.instance.rejectCall(callData).catchError((_) {});
      return;
    }
    setState(() => _isCallActive = true);
    Navigator.of(context).pushNamed(
      AppRoutes.incomingCall,
      arguments: {
        'callData': callData,
        'callerName': callData.callerId,
        'callerAvatarUrl': null,
        'onAccept': () => _handleCallAccepted(callData),
        'onReject': () => _handleCallRejected(callData),
      },
    );
  }

  void _handleCallAccepted(CallData callData) async {
    // Only the callee should call acceptCall(). The caller receives this
    // callback via Realtime and must not accept again.
    final currentMember = ref.read(currentMemberProvider).asData?.value;
    if (currentMember != null && currentMember.id == callData.calleeId) {
      try {
        await CallService.instance.acceptCall(callData);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
        return;
      }
    }
    if (mounted) {
      setState(() => _isCallActive = true);
      try {
        Navigator.of(context).pop();
      } catch (_) {
        // ignore — the call screen may already be gone
      }
      Navigator.of(context).pushNamed(
        AppRoutes.activeCall,
        arguments: {
          'callData': callData,
          'remoteName': _otherParticipant?.name ?? callData.calleeId,
          'remoteAvatarUrl': _otherParticipant?.avatarUrl,
          'onEndCall': () => _handleCallEnded(callData),
        },
      );
    }
  }

  void _handleCallEnded(CallData callData) async {
    final wasActive = _isCallActive;
    try {
      await CallService.instance.endCall();
    } catch (_) {}
    if (mounted) {
      setState(() => _isCallActive = false);
      if (wasActive) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleCallCancelled(CallData callData) async {
    final wasActive = _isCallActive;
    try {
      await CallService.instance.cancelCall();
    } catch (_) {}
    if (mounted) {
      setState(() => _isCallActive = false);
      if (wasActive) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleCallRejected(CallData callData) async {
    final wasActive = _isCallActive;
    try {
      await CallService.instance.rejectCall(callData);
    } catch (_) {}
    if (mounted) {
      setState(() => _isCallActive = false);
      if (wasActive) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleGroupIncomingCall(GroupCallData callData) {
    if (_isCallActive) {
      // Déjà en appel — ignore la nouvelle invitation
      return;
    }
    setState(() => _isCallActive = true);
    final caller = _allParticipants.firstWhere(
      (m) => m.id == callData.callerId,
      orElse: () => const Member(id: '', name: 'Inconnu', profession: '', city: '', country: ''),
    );
    Navigator.of(context).pushNamed(
      AppRoutes.groupIncomingCall,
      arguments: {
        'callData': callData,
        'callerName': caller.name,
        'callerAvatarUrl': caller.avatarUrl,
        'onAccept': () => _handleGroupCallAccepted(callData),
        'onReject': () => _handleGroupCallRejected(callData),
      },
    );
  }

  Future<void> _handleGroupCallAccepted(GroupCallData callData) async {
    try {
      await GroupCallService.instance.acceptGroupCall(callData);
      if (mounted) {
        setState(() => _isCallActive = true);
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(
          AppRoutes.groupActiveCall,
          arguments: {
            'callData': callData,
            'onEndCall': () => _handleGroupCallLeave(callData),
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCallActive = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _handleGroupCallRejected(GroupCallData callData) async {
    final wasActive = _isCallActive;
    try {
      await GroupCallService.instance.rejectGroupCall(callData);
    } catch (_) {}
    if (mounted) {
      setState(() => _isCallActive = false);
      if (wasActive) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleGroupCallLeave(GroupCallData callData) async {
    final wasActive = _isCallActive;
    try {
      final currentMember = ref.read(currentMemberProvider);
      final member = currentMember.asData?.value;
      if (member != null && member.id == callData.callerId) {
        await GroupCallService.instance.endGroupCall();
      } else {
        await GroupCallService.instance.leaveGroupCall();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isCallActive = false);
      if (wasActive) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleGroupCallCancel(GroupCallData callData) async {
    final wasActive = _isCallActive;
    try {
      await GroupCallService.instance.cancelGroupCall(callData);
    } catch (_) {}
    if (mounted) {
      setState(() => _isCallActive = false);
      if (wasActive) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleGroupCallEnded(GroupCallData callData) async {
    final wasActive = _isCallActive;
    if (mounted) {
      setState(() => _isCallActive = false);
      if (wasActive) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _startCall({required CallType callType}) async {
    final currentMember = ref.read(currentMemberProvider);
    if (currentMember is! AsyncData<Member?> || currentMember.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour appeler.')),
      );
      return;
    }

    final callerMemberId = currentMember.value!.id;

    if (_isGroup) {
      await _startGroupCall(callType: callType, callerMemberId: callerMemberId);
      return;
    }

    final otherParticipant = await _repo.findOtherParticipant(
      widget.conversationId,
      callerMemberId,
    );
    if (otherParticipant == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de trouver le correspondant.')),
        );
      }
      return;
    }

    if (callType == CallType.video) {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission caméra requise pour les appels vidéo.')),
          );
        }
        return;
      }
    }

    try {
      // Vérifie la configuration Agora avant de tenter l'appel
      if (!AppConstants.hasAgoraConfig) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Appels désactivés. Ajoutez AGORA_APP_ID dans votre .env\n'
                'Créez un projet sur https://console.agora.io',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      setState(() => _isCallActive = true);
      final callData = await CallService.instance.startCall(
        callerMemberId: callerMemberId,
        calleeMemberId: otherParticipant.id,
        conversationId: widget.conversationId,
        callType: callType,
      );

      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRoutes.outgoingCall,
          arguments: {
            'callData': callData,
            'calleeName': otherParticipant.name,
            'calleeAvatarUrl': otherParticipant.avatarUrl,
            'onCancel': () => _handleCallCancelled(callData),
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCallActive = false);
        final cause = e is ServerException ? e.cause : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échec de l\'appel : ${cause ?? e}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _startGroupCall({
    required CallType callType,
    required String callerMemberId,
  }) async {
    if (callType == CallType.video) {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission caméra requise pour les appels vidéo.')),
          );
        }
        return;
      }
    }

    final participantIds = _allParticipants
        .where((m) => m.id != callerMemberId)
        .map((m) => m.id)
        .toList(growable: false);

    if (participantIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun participant trouvé pour l\'appel de groupe.')),
        );
      }
      return;
    }

    try {
      setState(() => _isCallActive = true);
      final callData = await GroupCallService.instance.startGroupCall(
        callerMemberId: callerMemberId,
        conversationId: widget.conversationId,
        callType: callType,
        participantMemberIds: participantIds,
      );

      if (mounted) {
        final participantNames = _allParticipants
            .where((m) => m.id != callerMemberId)
            .map((m) => m.name)
            .toList(growable: false);

        Navigator.of(context).pushNamed(
          AppRoutes.groupOutgoingCall,
          arguments: {
            'callData': callData,
            'participantNames': participantNames,
            'onCancel': () => _handleGroupCallCancel(callData),
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCallActive = false);
        final cause = e is ServerException ? e.cause : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'appel de groupe : ${cause ?? e}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ── Microphone permission dialog ─────────────────────────────────────────

  void _showMicrophonePermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone requis'),
        content: const Text(
          'La permission microphone a été refusée définitivement. '
          'Veuillez l\'activer dans les Réglages de votre appareil '
          'pour pouvoir envoyer des messages vocaux.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Ouvrir les Réglages'),
          ),
        ],
      ),
    );
  }

  // ── Format helpers ───────────────────────────────────────────────────

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final other = _otherParticipant;
    final displayName = _isGroup
        ? 'Groupe (${_allParticipants.length})'
        : (other?.name ?? 'Chargement…');
    final avatarUrl = _isGroup ? null : other?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(
                      _isGroup ? PhosphorIcons.users : PhosphorIcons.user,
                      color: AppColors.onPrimary,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: AppTextStyles.headlineMd,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIcons.phone),
            onPressed: () => _startCall(callType: CallType.audio),
          ),
          IconButton(
            icon: const Icon(PhosphorIcons.videoCamera),
            onPressed: () => _startCall(callType: CallType.video),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final prevMsg =
                          index > 0 ? _messages[index - 1] : null;
                      return _buildMessageBubble(msg,
                          prevMessage: prevMsg);
                    },
                  ),
          ),
          VoiceRecorderBar(
            textController: _textController,
            focusNode: _focusNode,
            isRecording: _isRecording,
            isPaused: _isPaused,
            elapsed: _elapsed,
            isLoading: _isUploading,
            onStartRecording: _startVoiceRecording,
            onVoiceMessageRecorded: (duration) {
              // Appelé quand l'utilisateur relâche après un appui long
              _sendVoiceRecording();
            },
            onSendText: (text) {
              _textController.text = text;
              _sendMessage();
            },
            onCancel: _cancelVoiceRecording,
            onLock: _lockVoiceRecording,
            onTogglePause: _togglePauseRecording,
            onDelete: _deleteVoiceRecording,
            onSend: _sendVoiceRecording,
          ),
        ],
      ),
    );
  }

  // ── Message bubble ───────────────────────────────────────────────────────

  /// Détermine si l'en-tête expéditeur (avatar + nom) doit être affiché
  /// pour ce message.
  ///
  /// Règles :
  /// - Jamais pour ses propres messages.
  /// - Toujours en conversation de groupe, SAUF si le message précédent
  ///   vient du même expéditeur (groupement visuel).
  /// - En 1-to-1 : affiché seulement pour le premier message d'une série
  ///   du même expéditeur (évite la répétition).
  bool _shouldShowSenderHeader(ChatMessage message, ChatMessage? prev) {
    if (message.isMine) return false;
    // Premier message : toujours afficher
    if (prev == null) return true;
    // Si l'expéditeur change, afficher le header
    if (prev.senderId != message.senderId) return true;
    // Même expéditeur que le précédent → ne pas répéter
    return false;
  }

  Widget _buildMessageBubble(ChatMessage message,
      {ChatMessage? prevMessage}) {
    final isMine = message.isMine;
    final bubbleColor = isMine ? AppColors.primary : AppColors.surface;
    final textColor = isMine ? AppColors.onPrimary : AppColors.onSurface;
    final showSender = _shouldShowSenderHeader(message, prevMessage);

    final msgType = message.metadata?['msg_type'] as String?;
    final content = message.content;

    Widget contentWidget;

    switch (msgType) {
      case 'image':
        contentWidget = _buildImageMessage(content, isMine);
        break;
      case 'audio':
        contentWidget = VoiceMessageBubble(
          isMine: isMine,
          message: message,
          avatarInitials: showSender && _isGroup
              ? _initials(message.senderName)
              : null,
        );
        break;
      case 'video':
        contentWidget = _buildVideoMessage(content, isMine);
        break;
      case 'file':
        contentWidget = _buildFileMessage(message, isMine);
        break;
      case 'post_share':
        contentWidget = _buildPostShareMessage(message, isMine);
        break;
      case 'call':
        contentWidget = _buildCallMessage(message, isMine);
        break;
      default:
        contentWidget = Text(
          content,
          style: AppTextStyles.bodyMd.copyWith(color: textColor),
        );
    }

    // ── Colonne principale : header expéditeur (optionnel) + bulle ────
    final bubble = Container(
      margin: EdgeInsets.only(
        bottom: 8,
        top: showSender ? 2 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          contentWidget,
          const SizedBox(height: 4),
          Text(
            _formatTime(message.createdAt),
            style: AppTextStyles.labelSm.copyWith(
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );

    // Si c'est mon message : juste la bulle alignée à droite
    if (isMine) {
      return Align(
        alignment: Alignment.centerRight,
        child: bubble,
      );
    }

    // ── Message des autres : avatar + nom + bulle ──────────────────────
    return Padding(
      padding: EdgeInsets.only(
        bottom: showSender ? 2 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (32px) — invisible mais garde l'espace si masqué
          SizedBox(
            width: 32,
            height: showSender ? 32 : 0,
            child: showSender
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryFixed,
                    backgroundImage: message.senderAvatarUrl != null
                        ? NetworkImage(message.senderAvatarUrl!)
                        : null,
                    child: message.senderAvatarUrl == null
                        ? Text(
                            _initials(message.senderName),
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          )
                        : null,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom de l'expéditeur
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                bubble,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(String url, bool isMine) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surfaceContainerHigh,
          child: const Icon(
            PhosphorIcons.image,
            color: AppColors.outline,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoMessage(String url, bool isMine) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              PhosphorIcons.playCircle,
              size: 48,
              color: isMine ? Colors.white.withValues(alpha: 0.8) : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Vidéo',
              style: AppTextStyles.labelSm.copyWith(
                color: isMine ? Colors.white.withValues(alpha: 0.8) : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(ChatMessage message, bool isMine) {
    final fileName = message.metadata?['file_name'] as String? ?? 'Document';
    final url = message.content;

    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? Colors.white.withValues(alpha: 0.15) : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.file,
              color: isMine ? Colors.white : AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isMine ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Fichier',
                    style: AppTextStyles.labelSm.copyWith(
                      color: isMine ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostShareMessage(ChatMessage message, bool isMine) {
    final postId = message.metadata?['post_id'] as String?;
    final postContent = message.metadata?['post_content'] as String? ?? message.content;

    return GestureDetector(
      onTap: () {
        if (postId != null && postId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.feed,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? Colors.white.withValues(alpha: 0.15) : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.article,
              color: isMine ? Colors.white : AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Post partagé',
                    style: AppTextStyles.labelSm.copyWith(
                      color: isMine ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (postContent.isNotEmpty)
                    Text(
                      postContent,
                      style: AppTextStyles.labelSm.copyWith(
                        color: isMine ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallMessage(ChatMessage message, bool isMine) {
    final callType = message.metadata?['call_type'] as String? ?? 'audio';
    final callStatus = message.metadata?['call_status'] as String? ?? 'ended';
    final duration = message.metadata?['duration'] as String?;
    final isGroup = message.metadata?['is_group'] == true;

    final isVideo = callType == 'video';

    // Icône selon le statut et le type
    IconData icon;
    Color iconColor;
    String label;

    switch (callStatus) {
      case 'ended':
        icon = isVideo ? PhosphorIcons.videoCamera : PhosphorIcons.phone;
        iconColor = AppColors.primary;
        label = isGroup
            ? 'Appel de groupe terminé'
            : 'Appel terminé';
        break;
      case 'rejected':
        icon = PhosphorIcons.phoneX;
        iconColor = AppColors.error;
        label = 'Appel refusé';
        break;
      case 'cancelled':
        icon = PhosphorIcons.phoneX;
        iconColor = AppColors.error;
        label = 'Appel manqué';
        break;
      case 'missed':
        icon = PhosphorIcons.phoneX;
        iconColor = AppColors.error;
        label = 'Appel manqué';
        break;
      default:
        icon = PhosphorIcons.phone;
        iconColor = AppColors.onSurfaceVariant;
        label = 'Appel';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: isMine ? Colors.white : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (duration != null && callStatus == 'ended')
                  Text(
                    duration,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extrait les initiales d'un nom (ex: "Amadou Diallo" → "AD").
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

}
