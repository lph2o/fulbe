import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/data/models/conversation.dart' show ChatMessage;
import '../../core/theme/app_colors.dart';

// =====================================================================
// FULƁE CONNECT — VOICE MESSAGE BUBBLE (lecture)
// Reproduit les fonctionnalités de lecture vocale de WhatsApp :
//   - Bouton play/pause circulaire
//   - Waveform avec progression colorée (lu / non lu)
//   - Seek tactile (tap + drag sur la waveform)
//   - Compteur de temps (durée totale <-> temps écoulé pendant lecture)
//   - Vitesse de lecture cyclique 1x -> 1.5x -> 2x
//   - Indicateur "non écouté" (pastille) pour les messages reçus
//   - Avatar optionnel avec badge micro (utile en groupe)
//
// Palette identique aux autres écrans Fulɓe Connect.
// =====================================================================

// ---------------------------------------------------------------------
// VITESSE DE LECTURE — cycle 1x -> 1.5x -> 2x -> 1x
// ---------------------------------------------------------------------
enum _VoiceSpeed { x1, x1_5, x2 }

extension _VoiceSpeedX on _VoiceSpeed {
  double get rate {
    switch (this) {
      case _VoiceSpeed.x1:
        return 1.0;
      case _VoiceSpeed.x1_5:
        return 1.5;
      case _VoiceSpeed.x2:
        return 2.0;
    }
  }

  String get label {
    switch (this) {
      case _VoiceSpeed.x1:
        return '1x';
      case _VoiceSpeed.x1_5:
        return '1.5x';
      case _VoiceSpeed.x2:
        return '2x';
    }
  }

  _VoiceSpeed get next {
    switch (this) {
      case _VoiceSpeed.x1:
        return _VoiceSpeed.x1_5;
      case _VoiceSpeed.x1_5:
        return _VoiceSpeed.x2;
      case _VoiceSpeed.x2:
        return _VoiceSpeed.x1;
    }
  }
}

// ---------------------------------------------------------------------
// WIDGET PRINCIPAL
// ---------------------------------------------------------------------
class VoiceMessageBubble extends StatefulWidget {
  /// true = message envoyé (bulle pleine, alignée à droite)
  /// false = message reçu (bulle blanche, alignée à gauche)
  final bool isMine;

  /// Le message de chat contenant les métadonnées (duration, waveform, file_url).
  final ChatMessage message;

  /// Pour les messages reçus : indique si le message a déjà été écouté.
  /// Si false, une pastille "non écouté" est affichée sur l'avatar.
  final bool isPlayed;

  /// Initiales affichées dans l'avatar (utile en conversation de
  /// groupe). Si null, aucun avatar n'est affiché (cas standard d'une
  /// conversation 1-to-1, comme sur WhatsApp).
  final String? avatarInitials;

  /// Couleur de fond de l'avatar.
  final Color avatarColor;

  const VoiceMessageBubble({
    super.key,
    required this.isMine,
    required this.message,
    this.isPlayed = true,
    this.avatarInitials,
    this.avatarColor = AppColors.primaryFixed,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late List<double> _amplitudes;
  bool _played = false;

  // ── AudioPlayer ──────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<void>? _stateSub;
  StreamSubscription<void>? _positionSub;
  StreamSubscription<void>? _durationSub;
  _VoiceSpeed _speed = _VoiceSpeed.x1;

  static const int _barCount = 32;

  @override
  void initState() {
    super.initState();
    _amplitudes = _loadWaveform();
    _played = widget.isPlayed;
    _setupPlayer();
  }

  List<double> _loadWaveform() {
    final waveformData =
        widget.message.metadata?['waveform'] as List<dynamic>?;

    if (waveformData != null && waveformData.isNotEmpty) {
      final samples = waveformData
          .map((v) => double.tryParse(v.toString()) ?? 0.0)
          .toList(growable: false);
      return _resample(samples, _barCount);
    } else {
      // Fallback : waveform déterministe pour les anciens messages
      final rng = Random(widget.message.id.hashCode);
      return List.generate(_barCount, (i) {
        final base = 0.25 + rng.nextDouble() * 0.7;
        final wave = 0.15 * sin(i / 3);
        return (base + wave).clamp(0.12, 1.0);
      });
    }
  }

  void _setupPlayer() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  double get _progress =>
      _duration.inMilliseconds > 0
          ? (_position.inMilliseconds / _duration.inMilliseconds)
              .clamp(0.0, 1.0)
          : 0.0;

  bool get _isPlaying => _playerState == PlayerState.playing;

  Duration get _remaining =>
      _duration.inMilliseconds > 0
          ? _duration - _position
          : _totalDurationFromMeta;

  Duration get _totalDurationFromMeta {
    final raw = widget.message.metadata?['duration'] as String?;
    if (raw == null) return Duration.zero;
    final parts = raw.split(':');
    if (parts.length != 2) return Duration.zero;
    final min = int.tryParse(parts[0]) ?? 0;
    final sec = int.tryParse(parts[1]) ?? 0;
    return Duration(minutes: min, seconds: sec);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -------------------------------------------------------------
  // LECTURE
  // -------------------------------------------------------------
  Future<void> _togglePlay() async {
    final fileUrl = widget.message.metadata?['file_url'] as String?;
    if (fileUrl == null || fileUrl.isEmpty) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      // Rejouer depuis le début si terminé
      if (_playerState == PlayerState.completed ||
          _playerState == PlayerState.stopped) {
        await _player.play(UrlSource(fileUrl));
      } else {
        await _player.resume();
      }
      if (mounted) setState(() => _played = true);
    }
  }

  Future<void> _seekTo(double value) async {
    final target = (value.clamp(0.0, 1.0) *
            _duration.inMilliseconds)
        .round();
    await _player.seek(Duration(milliseconds: target));
    if (mounted) setState(() => _played = true);
  }

  void _cycleSpeed() {
    setState(() => _speed = _speed.next);
    _player.setPlaybackRate(_speed.rate);
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    final playedColor = isMine ? Colors.white : AppColors.primary;
    final unplayedColor = isMine
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xFFD9DDDA);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          border: isMine
              ? null
              : Border.all(
                  color: Colors.black.withValues(alpha: 0.07), width: 0.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMine ? 18 : 4),
            topRight: Radius.circular(isMine ? 4 : 18),
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.avatarInitials != null) ...[
              _buildAvatar(isMine),
              const SizedBox(width: 8),
            ],
            _buildPlayButton(isMine),
            const SizedBox(width: 8),
            Expanded(child: _buildWaveformAndMeta(isMine, playedColor, unplayedColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isMine) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isMine ? Colors.white.withValues(alpha: 0.15) : widget.avatarColor,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.avatarInitials!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isMine ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        // Badge micro
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
              border: Border.all(
                  color: isMine ? AppColors.primary : AppColors.surface,
                  width: 2),
            ),
            child: const Icon(PhosphorIcons.microphone,
                size: 9, color: Colors.white),
          ),
        ),
        // Pastille "non écouté"
        if (!isMine && !_played)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayButton(bool isMine) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMine ? Colors.white : AppColors.primary,
        ),
        child: Icon(
          _isPlaying ? PhosphorIcons.pauseFill : PhosphorIcons.playFill,
          color: isMine ? AppColors.primary : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildWaveformAndMeta(
      bool isMine, Color playedColor, Color unplayedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 28,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) =>
                    _seekTo(d.localPosition.dx / constraints.maxWidth),
                onHorizontalDragUpdate: (d) =>
                    _seekTo(d.localPosition.dx / constraints.maxWidth),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 28),
                  painter: _WaveformPainter(
                    amplitudes: _amplitudes,
                    progress: _isPlaying || _playerState == PlayerState.paused
                        ? _progress
                        : 0.0,
                    playedColor: playedColor,
                    unplayedColor: unplayedColor,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              _isPlaying || _progress > 0
                  ? _fmt(_remaining)
                  : _fmt(_totalDurationFromMeta),
              style: TextStyle(
                fontSize: 11,
                color: isMine                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _cycleSpeed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isMine
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: isMine
                      ? null
                      : Border.all(
                          color: Colors.black.withValues(alpha: 0.07), width: 0.5),
                ),
                child: Text(
                  _speed.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isMine
                        ? Colors.white
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<double> _resample(List<double> samples, int target) {
    if (target <= 1 || samples.isEmpty) return samples;
    if (samples.length == target) return samples;
    final result = <double>[];
    for (int i = 0; i < target; i++) {
      final srcIdx = (i / (target - 1)) * (samples.length - 1);
      final lo = srcIdx.floor();
      final hi = (lo + 1).clamp(0, samples.length - 1);
      final frac = srcIdx - lo;
      result.add(samples[lo] + (samples[hi] - samples[lo]) * frac);
    }
    return result;
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------
// WAVEFORM PAINTER
// ---------------------------------------------------------------------
class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress; // 0.0 - 1.0
  final Color playedColor;
  final Color unplayedColor;

  _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    const barWidth = 3.0;
    final count = amplitudes.length;
    final gap = (size.width - barWidth * count) / (count - 1);
    final playedBars = (progress * count).floor();

    for (var i = 0; i < count; i++) {
      final x = i * (barWidth + gap);
      final h = (amplitudes[i] * size.height).clamp(4.0, size.height);
      final paint = Paint()
        ..color = i <= playedBars ? playedColor : unplayedColor
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;
      final y0 = (size.height - h) / 2;
      final y1 = y0 + h;
      canvas.drawLine(Offset(x, y0), Offset(x, y1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.amplitudes != amplitudes;
  }
}
