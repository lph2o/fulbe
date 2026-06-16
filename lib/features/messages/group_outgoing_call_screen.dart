import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/services/call_service.dart' show CallType;
import '../../core/services/group_call_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/fc_card.dart';

/// Écran d'appel de groupe sortant (en cours d'invitation).
class GroupOutgoingCallScreen extends StatelessWidget {
  final GroupCallData callData;
  final List<String> participantNames;
  final VoidCallback onCancel;

  const GroupOutgoingCallScreen({
    super.key,
    required this.callData,
    required this.participantNames,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = callData.callType == CallType.video;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Animation de pulsation
            _PulsingRing(
              child: Icon(
                isVideo ? PhosphorIcons.videoCamera : PhosphorIcons.phone,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'Appel de groupe ${isVideo ? 'vidéo' : 'vocal'}',
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'En attente de participants…',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            // Liste des participants invités
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: participantNames.map((name) {
                  return Chip(
                    avatar: FcAvatar(
                      initials: name.isNotEmpty ? name.substring(0, 1) : '?',
                      size: 24,
                      showBorder: false,
                    ),
                    label: Text(name),
                    backgroundColor: AppColors.background,
                  );
                }).toList(),
              ),
            ),
            const Spacer(flex: 3),
            // Bouton annuler
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.stackLg,
              ),
              child: _CallActionButton(
                icon: PhosphorIcons.phoneDisconnect,
                label: 'Annuler',
                color: AppColors.error,
                onTap: onCancel,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  final Widget child;
  const _PulsingRing({required this.child});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: 0.3 + (_animation.value - 1.0) * 0.7,
              ),
              width: 2,
            ),
          ),
          child: Center(child: widget.child),
        );
      },
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
