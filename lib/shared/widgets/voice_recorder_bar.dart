import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/theme/app_colors.dart';

// =====================================================================
// FULƁE CONNECT — VOICE RECORDER BAR (enregistrement)
// Reproduit les interactions d'enregistrement vocal de WhatsApp :
//   - Maintenir le micro pour enregistrer
//   - Glisser vers la gauche pour annuler ("Glisser pour annuler")
//   - Glisser vers le haut pour verrouiller l'enregistrement
//   - Mode verrouillé : pause / reprise, suppression, envoi
//   - Minuteur en temps réel + indicateur d'enregistrement pulsant
//   - Retour haptique sur verrouillage / annulation
//
// Palette identique aux autres écrans Fulɓe Connect.
// =====================================================================

// Distances de glissement (en px) pour déclencher annulation / verrouillage.
const double _kCancelThreshold = 110;
const double _kLockThreshold = 80;

enum _RecState { idle, recording, locked }

class VoiceRecorderBar extends StatefulWidget {
  /// Contrôleur de texte optionnel. Si fourni, le parent peut écouter
  /// les changements (ex: pour les @mentions) et insérer du texte.
  final TextEditingController? textController;

  /// FocusNode optionnel.
  final FocusNode? focusNode;

  /// Appelé quand l'utilisateur démarre l'enregistrement.
  /// Le parent doit retourner `true` si l'enregistrement a bien démarré
  /// (après vérification des permissions, etc.).
  final Future<bool> Function()? onStartRecording;

  /// Appelé quand l'enregistrement est terminé et doit être envoyé.
  /// [duration] = durée totale.
  final ValueChanged<Duration>? onVoiceMessageRecorded;

  /// Appelé quand l'utilisateur envoie un message texte.
  final ValueChanged<String>? onSendText;

  /// Appelé quand un enregistrement est annulé.
  final VoidCallback? onCancel;

  /// Appelé quand l'utilisateur veut attacher un fichier (photo, vidéo, doc).
  final VoidCallback? onAttach;

  /// Appelé quand l'utilisateur veut ouvrir le picker emoji.
  final VoidCallback? onEmojiTap;

  /// Timer externe pour suivre la durée d'enregistrement.
  /// Le parent maintient ce timer et le passe ici pour l'affichage.
  final Duration elapsed;

  /// Si true, l'enregistrement est en pause.
  final bool isPaused;

  /// État d'enregistrement courant (géré par le parent).
  final bool isRecording;

  /// Passe en mode verrouillé (géré par le parent).
  final VoidCallback? onLock;

  /// Bascule pause/reprise (géré par le parent).
  final VoidCallback? onTogglePause;

  /// Supprime l'enregistrement en mode verrouillé.
  final VoidCallback? onDelete;

  /// Envoie l'enregistrement en mode verrouillé.
  final VoidCallback? onSend;

  /// Si true, affiche un indicateur de chargement dans le bouton
  /// de fin de ligne (upload d'image, vidéo ou message vocal en cours).
  final bool isLoading;

  const VoiceRecorderBar({
    super.key,
    this.textController,
    this.focusNode,
    this.onStartRecording,
    this.onVoiceMessageRecorded,
    this.onSendText,
    this.onCancel,
    this.onAttach,
    this.onEmojiTap,
    this.elapsed = Duration.zero,
    this.isPaused = false,
    this.isRecording = false,
    this.onLock,
    this.onTogglePause,
    this.onDelete,
    this.onSend,
    this.isLoading = false,
  });

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar>
    with SingleTickerProviderStateMixin {
  static const _animDuration = Duration(milliseconds: 250);
  static const _animCurve = Curves.easeOutCubic;

  late final TextEditingController _controller;
  late final AnimationController _pulseController;

  _RecState _state = _RecState.idle;
  Offset _dragOffset = Offset.zero;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.textController ?? TextEditingController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Only dispose the controller if we created it ourselves
    if (widget.textController == null) _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VoiceRecorderBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the parent stops recording (cancel or send from locked mode),
    // reset our internal state back to idle.
    if (!widget.isRecording && oldWidget.isRecording) {
      setState(() => _state = _RecState.idle);
    }
  }

  double get _cancelProgress =>
      (-_dragOffset.dx / _kCancelThreshold).clamp(0.0, 1.0);

  double get _lockProgress =>
      (-_dragOffset.dy / _kLockThreshold).clamp(0.0, 1.0);

  // -------------------------------------------------------------
  // CYCLE DE VIE DE L'ENREGISTREMENT
  // -------------------------------------------------------------
  Future<bool> _startRecording() async {
    if (_state != _RecState.idle) return false;
    final started = await widget.onStartRecording?.call() ?? false;
    if (!started || !mounted) return false;

    HapticFeedback.mediumImpact();
    setState(() {
      _state = _RecState.recording;
      _dragOffset = Offset.zero;
    });
    return true;
  }

  /// Tap simple sur le micro : démarre l'enregistrement et verrouille
  /// immédiatement (mode "WhatsApp tap-to-record").
  void _tapToRecord() async {
    if (_state != _RecState.idle) return;
    final started = await _startRecording();
    if (!started || !mounted) return;
    _lockRecording();
  }

  void _updateDrag(Offset offset) {
    if (_state != _RecState.recording) return;
    setState(() => _dragOffset = offset);
    if (_lockProgress >= 1) {
      _lockRecording();
    } else if (_cancelProgress >= 1) {
      _cancelRecording();
    }
  }

  void _lockRecording() {
    HapticFeedback.heavyImpact();
    widget.onLock?.call();
    setState(() {
      _state = _RecState.locked;
      _dragOffset = Offset.zero;
    });
  }

  void _cancelRecording() {
    HapticFeedback.lightImpact();
    widget.onCancel?.call();
    setState(() {
      _state = _RecState.idle;
      _dragOffset = Offset.zero;
    });
  }

  /// Relâchement du doigt pendant un appui maintenu (état "recording").
  void _endLongPress() {
    if (_state == _RecState.recording) {
      _finishAndSend();
    }
  }

  void _finishAndSend() {
    final duration = widget.elapsed;
    setState(() {
      _state = _RecState.idle;
      _dragOffset = Offset.zero;
    });
    if (duration.inMilliseconds > 300) {
      widget.onVoiceMessageRecorded?.call(duration);
    }
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText?.call(text);
    _controller.clear();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: _animDuration,
          switchInCurve: _animCurve,
          switchOutCurve: _animCurve,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _state == _RecState.recording
              ? _buildLockPill(key: const ValueKey('lockPill'))
              : const SizedBox.shrink(key: ValueKey('noPill')),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
                top: BorderSide(
                    color: AppColors.outlineVariant, width: 0.3)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: SafeArea(top: false, child: _buildBar()),
        ),
      ],
    );
  }

  /// Pastille flottante "glisser vers le haut pour verrouiller",
  /// visible uniquement pendant l'enregistrement non verrouillé.
  Widget _buildLockPill({Key? key}) {
    final t = _lockProgress;
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: 14, bottom: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Transform.translate(
          offset: Offset(0, -t * 6),
          child: Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color:
                  t > 0.5 ? AppColors.primaryFixed : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.caretUp,
                  size: 16,
                  color: t > 0.5
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Icon(
                  PhosphorIcons.lockSimple,
                  size: 16,
                  color: t > 0.5
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar() {
    return AnimatedSwitcher(
      duration: _animDuration,
      switchInCurve: _animCurve,
      switchOutCurve: _animCurve,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _state == _RecState.locked
          ? _buildLockedRow(key: const ValueKey('locked'))
          : _buildStandardRow(key: const ValueKey('standard')),
    );
  }

  Widget _buildStandardRow({Key? key}) {
    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: _animDuration,
          curve: _animCurve,
          alignment: Alignment.centerLeft,
          child: _state == _RecState.idle
              ? IconButton(
                  icon: const Icon(PhosphorIcons.paperclip,
                      color: AppColors.onSurfaceVariant, size: 22),
                  onPressed: widget.onAttach,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: _animDuration,
            switchInCurve: _animCurve,
            switchOutCurve: _animCurve,
            child: _state == _RecState.idle
                ? _buildTextField(key: const ValueKey('textField'))
                : _buildRecordingContent(key: const ValueKey('recording')),
          ),
        ),
        const SizedBox(width: 6),
        _buildTrailingButton(),
      ],
    );
  }

  // -------------------------------------------------------------
  // ÉTAT IDLE — champ de texte
  // -------------------------------------------------------------
  Widget _buildTextField({Key? key}) {
    return Container(
      key: key,
      constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _sendText(),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.onSurface),
              decoration: const InputDecoration(
                hintText: 'Écrire un message...',
                hintStyle: TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIcons.smiley,
                color: AppColors.onSurfaceVariant, size: 20),
            onPressed: widget.onEmojiTap,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ÉTAT RECORDING — minuteur + indication d'annulation
  // -------------------------------------------------------------
  Widget _buildRecordingContent({Key? key}) {
    return Container(
      key: key,
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.15).animate(
              CurvedAnimation(
                  parent: _pulseController, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatDuration(widget.elapsed),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          Opacity(
            opacity: (1 - _cancelProgress).clamp(0.0, 1.0),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.caretLeft,
                    size: 18, color: AppColors.onSurfaceVariant),
                SizedBox(width: 2),
                Text(
                  'Glisser pour annuler',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOUTON DE FIN DE LIGNE — texte (send), micro (record) ou spinner (loading)
  // -------------------------------------------------------------
  Widget _buildTrailingButton() {
    // Spinner pendant l'upload (image, vidéo, fichier, audio)
    if (widget.isLoading && _state == _RecState.idle) {
      return const SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (_hasText && _state == _RecState.idle) {
      return _circleButton(icon: PhosphorIcons.paperPlaneTilt, onTap: _sendText);
    }

    // Le micro est translaté selon le geste en cours : glisser vers la
    // gauche (annuler) ou vers le haut (verrouiller).
    final clamped = Offset(
      _dragOffset.dx.clamp(-130.0, 0.0),
      _dragOffset.dy.clamp(-70.0, 0.0),
    );

    return GestureDetector(
      onTap: _tapToRecord,
      onLongPressStart: (_) => _startRecording(),
      onLongPressMoveUpdate: (d) => _updateDrag(d.offsetFromOrigin),
      onLongPressEnd: (_) => _endLongPress(),
      onLongPressCancel: _endLongPress,
      child: Transform.translate(
        offset: clamped,
        child: _state == _RecState.recording
            ? _circleButton(
                icon: PhosphorIcons.microphone,
                diameter: 48,
                color: AppColors.error,
              )
            : _circleButton(
                icon: PhosphorIcons.microphone,
                filled: false,
              ),
      ),
    );
  }

  // -------------------------------------------------------------
  // ÉTAT LOCKED — pause/reprise, suppression, envoi
  // -------------------------------------------------------------
  Widget _buildLockedRow({Key? key}) {
    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(PhosphorIcons.trash,
              color: AppColors.onSurfaceVariant),
          onPressed: widget.onDelete,
          tooltip: 'Supprimer',
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                if (!widget.isPaused)
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.15).animate(
                      CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut),
                    ),
                    child: const CircleAvatar(
                      radius: 5,
                      backgroundColor: AppColors.error,
                    ),
                  )
                else
                  const Icon(PhosphorIcons.pauseCircle,
                      size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  _formatDuration(widget.elapsed),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onTogglePause,
                  child: Icon(
                    widget.isPaused
                        ? PhosphorIcons.microphone
                        : PhosphorIcons.pause,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _circleButton(
            icon: PhosphorIcons.paperPlaneTilt,
            onTap: widget.onSend ?? _finishAndSend),
      ],
    );
  }

  // -------------------------------------------------------------
  // BOUTON CIRCULAIRE GÉNÉRIQUE
  // -------------------------------------------------------------
  Widget _circleButton({
    required IconData icon,
    VoidCallback? onTap,
    bool filled = true,
    Color? color,
    double diameter = 42,
  }) {
    final isAccent = filled || color != null;
    final bg =
        color ?? (filled ? AppColors.primary : Colors.transparent);
    final fg = isAccent ? Colors.white : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _animDuration,
        curve: _animCurve,
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: AnimatedSwitcher(
          duration: _animDuration,
          switchInCurve: _animCurve,
          switchOutCurve: _animCurve,
          child: Icon(
            icon,
            key: ValueKey('$icon-$filled-$diameter-$color'),
            color: fg,
            size: isAccent ? 20 : 24,
          ),
        ),
      ),
    );
  }
}
