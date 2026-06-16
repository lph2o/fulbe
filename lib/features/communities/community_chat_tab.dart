// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/models/conversation.dart' show ChatMessage;
import '../../core/data/providers/data_providers.dart';
import '../../core/data/repositories/conversations_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/attachment_sheet.dart';
import '../../shared/widgets/voice_message_bubble.dart';
import '../../shared/widgets/voice_recorder_bar.dart';

/// Widget du chat instantané intégré dans l'onglet Chat d'une communauté.
class CommunityChatTab extends ConsumerStatefulWidget {
  final String communityId;
  final String currentMemberId;

  const CommunityChatTab({
    super.key,
    required this.communityId,
    required this.currentMemberId,
  });

  @override
  ConsumerState<CommunityChatTab> createState() => _CommunityChatTabState();
}

class _CommunityChatTabState extends ConsumerState<CommunityChatTab> {
  final _repo = const ConversationsRepository();
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _audioRecorder = AudioRecorder();
  final _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _conversationId;

  // ── Voice recording state ──────────────────────────────────
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _elapsed = Duration.zero;
  String? _recordingPath;
  Timer? _recordingTimer;
  bool _isUploading = false;
  String? _uploadFileName;
  String? _uploadFileSize;
  String? _pendingCaption;

  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      // Obtient/crée la conversation pour cette communauté
      final convId = await ref
          .read(communitiesRepositoryProvider)
          .getOrCreateConversation(widget.communityId);

      if (mounted) {
        setState(() => _conversationId = convId);
        _loadMessages();
        _listenToMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    try {
      final msgs = await _repo.fetchMessages(_conversationId!);
      if (mounted) {
        setState(() {
          _messages = msgs
              .map((m) => m.copyWith(
                    isMine: m.senderId == widget.currentMemberId,
                  ))
              .toList(growable: false);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToMessages() {
    if (_conversationId == null) return;
    _messagesChannel = Supabase.instance.client
        .channel('community_chat_${_conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: _conversationId!,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            var msg = ChatMessage.fromJson(record);
            if (widget.currentMemberId == msg.senderId) {
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    _textController.clear();
    _focusNode.requestFocus();

    try {
      await _repo.sendMessage(
        conversationId: _conversationId!,
        senderMemberId: widget.currentMemberId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'envoyer le message.")),
        );
      }
    }
  }

  // ── File attachments ─────────────────────────────────────────────────

  Future<void> _onAttachFile() async {
    final choice = await showModalBottomSheet<AttachmentType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AttachmentSheet(),
    );

    if (choice == null || !mounted || _conversationId == null) return;

    File? file;
    String? fileName;
    String metadataType;

    switch (choice) {
      case AttachmentType.photo:
        final xFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (xFile == null) return;
        file = File(xFile.path);
        fileName = 'photos/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        metadataType = 'image';
        break;

      case AttachmentType.gallery:
        final xFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (xFile == null) return;
        file = File(xFile.path);
        final ext = xFile.path.split('.').last;
        fileName = 'photos/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        metadataType = 'image';
        break;

      case AttachmentType.video:
        final xFile = await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (xFile == null) return;
        file = File(xFile.path);
        final ext = xFile.path.split('.').last;
        fileName = 'videos/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        metadataType = 'video';
        break;

      case AttachmentType.document:
        final result = await FilePicker.platform.pickFiles();
        if (result == null || result.files.isEmpty) return;
        final picked = result.files.first;
        if (picked.path == null) return;
        file = File(picked.path!);
        fileName = 'docs/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        metadataType = 'file';
        break;
    }

    if (!mounted || file == null) return;

    // Preview for images/videos
    if (metadataType == 'image' || metadataType == 'video') {
      String? caption;
      while (true) {
        String previewSize;
        try {
          previewSize = _formatFileSize(await file!.length());
        } catch (_) {
          previewSize = '—';
        }
        if (!mounted) return;

        caption = await showModalBottomSheet<String?>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SendPreviewSheet(
            file: file!,
            fileName: fileName!,
            metadataType: metadataType,
            fileSize: previewSize,
          ),
        );

        if (caption == null || !mounted) return;

        if (caption == SendPreviewSheetState.repickSentinel) {
          if (!mounted) return;
          final xFile = choice == AttachmentType.photo
              ? await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85)
              : metadataType == 'video'
                  ? await _imagePicker.pickVideo(source: ImageSource.gallery)
                  : await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
          if (xFile == null || !mounted) return;
          file = File(xFile.path);
          final ext = xFile.path.split('.').last;
          fileName = choice == AttachmentType.photo
              ? 'photos/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}.jpg'
              : metadataType == 'video'
                  ? 'videos/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}.$ext'
                  : 'photos/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
          continue;
        }
        break;
      }
      _pendingCaption = caption;
    }

    await _uploadAndSendFile(file!, fileName!, metadataType);
    _pendingCaption = null;
  }

  Future<void> _uploadAndSendFile(
    File file,
    String fileName,
    String metadataType,
  ) async {
    final displayName = fileName.split('/').last;
    setState(() {
      _isUploading = true;
      _uploadFileName = displayName;
      _uploadFileSize = 'Calcul…';
    });

    try {
      await Supabase.instance.client.storage
          .from('attachments')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: false));

      final publicUrl = Supabase.instance.client.storage
          .from('attachments')
          .getPublicUrl(fileName);

      final metadata = <String, dynamic>{'msg_type': metadataType};
      if (metadataType == 'file') {
        metadata['file_name'] = fileName.split('/').last;
      }
      final caption = _pendingCaption?.trim();
      if (caption != null && caption.isNotEmpty) {
        metadata['caption'] = caption;
      }

      await _repo.sendMessage(
        conversationId: _conversationId!,
        senderMemberId: widget.currentMemberId,
        content: publicUrl,
        metadata: metadata,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de l'envoi : $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadFileName = null;
          _uploadFileSize = null;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
  }

  // ── Voice recording ─────────────────────────────────────────────────

  Future<bool> _startVoiceRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission microphone requise.')),
        );
      }
      return false;
    }

    if (await _audioRecorder.isRecording()) return false;

    try {
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
      _elapsed = Duration.zero;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() => _elapsed += const Duration(milliseconds: 100));
      });

      if (mounted) setState(() { _isRecording = true; _isPaused = false; });
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

  void _togglePauseRecording() async {
    try {
      if (_isPaused) {
        await _audioRecorder.resume();
        _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (mounted) setState(() => _elapsed += const Duration(milliseconds: 100));
        });
      } else {
        await _audioRecorder.pause();
        _recordingTimer?.cancel();
      }
      if (mounted) setState(() => _isPaused = !_isPaused);
    } catch (_) {}
  }

  void _cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    try { await _audioRecorder.stop(); } catch (_) {}
    if (_recordingPath != null) {
      try { await File(_recordingPath!).delete(); } catch (_) {}
    }
    if (mounted) setState(() {
      _isRecording = false;
      _isPaused = false;
      _elapsed = Duration.zero;
      _recordingPath = null;
    });
  }

  void _deleteVoiceRecording() => _cancelVoiceRecording();

  void _lockVoiceRecording() {}

  Future<void> _sendVoiceRecording() async {
    _recordingTimer?.cancel();
    String? filePath;
    try { filePath = await _audioRecorder.stop(); } catch (_) {}

    final finalPath = filePath ?? _recordingPath;
    final duration = _elapsed;

    if (mounted) setState(() {
      _isRecording = false;
      _isPaused = false;
      _elapsed = Duration.zero;
      _isUploading = true;
      _recordingPath = null;
    });

    if (duration.inMilliseconds < 300 || finalPath == null) {
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    try {
      final file = File(finalPath);
      final fileName = 'voice/${widget.currentMemberId}/${DateTime.now().millisecondsSinceEpoch}.m4a';

      await Supabase.instance.client.storage
          .from('attachments')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: false));

      final publicUrl = Supabase.instance.client.storage
          .from('attachments')
          .getPublicUrl(fileName);

      final waveform = List.generate(32, (i) {
        final seed = (fileName.hashCode + i * 7) % 100;
        return 0.3 + (seed / 100) * 0.7;
      });

      final durStr = '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

      await _repo.sendMessage(
        conversationId: _conversationId!,
        senderMemberId: widget.currentMemberId,
        content: publicUrl,
        metadata: {
          'msg_type': 'audio',
          'duration': durStr,
          'file_url': publicUrl,
          'waveform': waveform,
        },
      );

      try { await file.delete(); } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de l'envoi vocal : $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.chatsTeardrop,
                          size: 48, color: AppColors.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun message pour le moment.\nSois le premier à écrire !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: _messages.length,
                  itemBuilder: (_, index) {
                    final msg = _messages[index];
                    final prev = index > 0 ? _messages[index - 1] : null;
                    return _buildMessageBubble(msg, prevMessage: prev);
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
          uploadFileName: _uploadFileName,
          uploadFileSize: _uploadFileSize,
          onAttach: _onAttachFile,
          onStartRecording: _startVoiceRecording,
          onVoiceMessageRecorded: (_) => _sendVoiceRecording(),
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
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {ChatMessage? prevMessage}) {
    final isMine = message.isMine;
    final bubbleColor = isMine ? AppColors.primary : AppColors.surface;
    final textColor = isMine ? AppColors.onPrimary : AppColors.onSurface;

    final msgType = message.metadata?['msg_type'] as String?;
    final content = message.content;

    Widget contentWidget;

    switch (msgType) {
      case 'image':
        contentWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            content,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surfaceContainerHigh,
              child: Icon(PhosphorIcons.image, color: AppColors.outline, size: 48),
            ),
          ),
        );
        break;
      case 'audio':
        contentWidget = VoiceMessageBubble(
          isMine: isMine,
          message: message,
        );
        break;
      case 'video':
        contentWidget = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(PhosphorIcons.playCircle, size: 48, color: isMine ? Colors.white.withValues(alpha: 0.8) : AppColors.primary),
            const SizedBox(height: 8),
            Text('Vidéo', style: AppTextStyles.labelSm.copyWith(color: isMine ? Colors.white.withValues(alpha: 0.8) : AppColors.onSurfaceVariant)),
          ]),
        );
        break;
      case 'file':
        final fileName = message.metadata?['file_name'] as String? ?? 'Document';
        contentWidget = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine ? Colors.white.withValues(alpha: 0.15) : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(PhosphorIcons.file, color: isMine ? Colors.white : AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(fileName, style: AppTextStyles.labelSm.copyWith(color: isMine ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text('Fichier', style: AppTextStyles.labelSm.copyWith(color: isMine ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurfaceVariant)),
            ])),
          ]),
        );
        break;
      default:
        contentWidget = Text(content, style: AppTextStyles.bodyMd.copyWith(color: textColor));
    }

    final bubble = Container(
      margin: EdgeInsets.only(bottom: 8, top: 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        contentWidget,
        const SizedBox(height: 4),
        Text(_formatTime(message.createdAt), style: AppTextStyles.labelSm.copyWith(color: textColor.withValues(alpha: 0.6))),
      ]),
    );

    if (isMine) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: 32, height: 32, child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryFixed,
          backgroundImage: message.senderAvatarUrl != null ? NetworkImage(message.senderAvatarUrl!) : null,
          child: message.senderAvatarUrl == null
              ? Text(_initials(message.senderName), style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11))
              : null,
        )),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(message.senderName, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          bubble,
        ])),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

