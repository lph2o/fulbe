import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/services/call_service.dart' show CallType;
import '../../core/services/group_call_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/fc_card.dart';

/// Écran d'appel de groupe en cours (audio ou vidéo).
///
/// Pour les appels vidéo : affiche une grille de vidéos pour tous les participants.
/// Pour les appels audio : affiche une grille d'avatars.
class GroupActiveCallScreen extends StatefulWidget {
  final GroupCallData callData;
  final VoidCallback onEndCall;

  const GroupActiveCallScreen({
    super.key,
    required this.callData,
    required this.onEndCall,
  });

  @override
  State<GroupActiveCallScreen> createState() => _GroupActiveCallScreenState();
}

class _GroupActiveCallScreenState extends State<GroupActiveCallScreen> {
  final _service = GroupCallService.instance;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
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
        child: Column(
          children: [
            // ── En-tête ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                left: AppSpacing.marginMobile,
                right: AppSpacing.marginMobile,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Appel de groupe',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _formattedTime,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Grille de participants ────────────────────────────────
            Expanded(
              child: ValueListenableBuilder<List<GroupCallParticipant>>(
                valueListenable: _service.participants,
                builder: (context, participants, _) {
                  return ValueListenableBuilder<List<int>>(
                    valueListenable: _service.remoteUids,
                    builder: (context, remoteUids, _) {
                      return _buildParticipantGrid(
                        isVideo: isVideo,
                        participants: participants,
                        remoteUids: remoteUids,
                      );
                    },
                  );
                },
              ),
            ),

            // ── Barre de contrôles ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.only(
                bottom: 32,
                left: AppSpacing.marginMobile,
                right: AppSpacing.marginMobile,
                top: 16,
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
      ),
    );
  }

  Widget _buildParticipantGrid({
    required bool isVideo,
    required List<GroupCallParticipant> participants,
    required List<int> remoteUids,
  }) {
    // Ajoute le participant local (caller) en premier
    final allParticipants = [
      const GroupCallParticipant(
        id: 'local',
        memberId: 'local',
        name: 'Vous',
        status: GroupCallParticipantStatus.joined,
      ),
      ...participants.where((p) => p.isJoined),
    ];

    if (allParticipants.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Détermine le nombre de colonnes selon le nombre de participants
    final crossAxisCount = allParticipants.length <= 2 ? 1 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: isVideo ? 3 / 4 : 1,
      ),
      itemCount: allParticipants.length,
      itemBuilder: (context, index) {
        final participant = allParticipants[index];
        final isLocal = participant.memberId == 'local';

        if (isVideo && isLocal) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black,
              child: _service.localVideoView(),
            ),
          );
        }

        if (isVideo && !isLocal) {
          // Trouve le remoteUid correspondant
          final uidIndex = index - 1;
          if (uidIndex < remoteUids.length) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black,
                child: _service.remoteVideoView(remoteUids[uidIndex]),
              ),
            );
          }
        }

        // Audio ou fallback vidéo
        return _ParticipantTile(
          name: participant.name,
          avatarUrl: participant.avatarUrl,
          isLocal: isLocal,
        );
      },
    );
  }
}

/// Tuile d'un participant (audio ou fallback vidéo).
class _ParticipantTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isLocal;

  const _ParticipantTile({
    required this.name,
    this.avatarUrl,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FcAvatar(
            imageUrl: avatarUrl,
            initials: name.isNotEmpty ? name.substring(0, 1) : '?',
            size: 80,
            showBorder: true,
          ),
          const SizedBox(height: 8),
          Text(
            isLocal ? '$name (Vous)' : name,
            style: AppTextStyles.labelMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton de contrôle circulaire.
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
