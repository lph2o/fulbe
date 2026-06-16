import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/services/call_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/fc_card.dart';

/// Écran d'appel en cours (audio ou vidéo).
///
/// Pour les appels vidéo : affiche la vidéo distante en plein écran
/// et la vidéo locale en picture-in-picture.
/// Pour les appels audio : affiche l'avatar du correspondant en grand.
class ActiveCallScreen extends StatefulWidget {
  final CallData callData;
  final String remoteName;
  final String? remoteAvatarUrl;
  final VoidCallback onEndCall;

  const ActiveCallScreen({
    super.key,
    required this.callData,
    required this.remoteName,
    this.remoteAvatarUrl,
    required this.onEndCall,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final _service = CallService.instance;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Force l'orientation portrait pendant l'appel
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  String get _formattedTime {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Restaure les orientations par défaut
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callData.callType == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child:    Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond : vidéo distante ou avatar audio ────────────────────
            ValueListenableBuilder<int?>(
              valueListenable: _service.remoteUid,
              builder: (context, remoteUid, _) {
                if (isVideo && remoteUid != null) {
                  return _service.remoteVideoView(remoteUid);
                }
                if (isVideo) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                }
                return _AudioBackground(
                  name: widget.remoteName,
                  avatarUrl: widget.remoteAvatarUrl,
                );
              },
            ),

            // ── Overlay UI ───────────────────────────────────────────────
            Column(
              children: [
                // En-tête
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: AppSpacing.marginMobile,
                    right: AppSpacing.marginMobile,
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.remoteName,
                        style: AppTextStyles.headlineMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            const Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _service.currentCall?.status == CallStatus.connected
                            ? _formattedTime
                            : (isVideo ? 'Appel vidéo…' : 'Appel vocal…'),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          shadows: [
                            const Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                const Spacer(),

                // ── Barre de contrôles ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.only(
                    bottom: 48,
                    left: AppSpacing.marginMobile,
                    right: AppSpacing.marginMobile,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: _service.isMuted
                                ? PhosphorIcons.microphoneSlash
                                : PhosphorIcons.microphone,
                            label: _service.isMuted ? 'Réactivé' : 'Muet',
                            isActive: _service.isMuted,
                            onTap: () async {
                              await _service.toggleMute();
                              if (mounted) setState(() {});
                            },
                          ),
                          if (isVideo)
                            _ControlButton(
                              icon: _service.isCameraOff
                                  ? PhosphorIcons.videoCameraSlash
                                  : PhosphorIcons.videoCamera,
                              label: _service.isCameraOff ? 'Caméra' : 'Cam. off',
                              isActive: _service.isCameraOff,
                              onTap: () async {
                                await _service.toggleCamera();
                                if (mounted) setState(() {});
                              },
                            ),
                          _ControlButton(
                            icon: _service.isSpeakerOn
                                ? PhosphorIcons.speakerHigh
                                : PhosphorIcons.speakerLow,
                            label: _service.isSpeakerOn ? 'Haut' : 'Oreille',
                            isActive: _service.isSpeakerOn,
                            onTap: () async {
                              await _service.toggleSpeaker();
                              if (mounted) setState(() {});
                            },
                          ),
                          if (isVideo)
                            _ControlButton(
                              icon: PhosphorIcons.arrowsClockwise,
                              label: 'Retourner',
                              onTap: () async {
                                await _service.switchCamera();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Bouton raccrocher
                      GestureDetector(
                        onTap: widget.onEndCall,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIcons.phoneDisconnect,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Vidéo locale (PIP) pour appel vidéo ──────────────────
            if (isVideo)
              Positioned(
                top: 80,
                right: AppSpacing.marginMobile,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: 140,
                    color: Colors.black,
                    child: _service.localVideoView(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fond pour un appel audio (avatar + dégradé).
class _AudioBackground extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _AudioBackground({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            AppColors.surface.withValues(alpha: 0.9),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FcAvatar(
              imageUrl: avatarUrl,
              initials: name.isNotEmpty ? name.substring(0, 1) : '?',
              size: 160,
              showBorder: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton de contrôle circulaire (mute, speaker, etc.).
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.onSurface : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
