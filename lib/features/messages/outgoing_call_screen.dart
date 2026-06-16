import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/services/call_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/fc_card.dart';

/// Écran d'appel sortant (plein écran).
///
/// Affiche l'avatar et le nom du correspondant, avec un indicateur
/// "Sonnerie en cours…" et un bouton pour annuler l'appel.
class OutgoingCallScreen extends StatelessWidget {
  final CallData callData;
  final String calleeName;
  final String? calleeAvatarUrl;
  final VoidCallback onCancel;

  const OutgoingCallScreen({
    super.key,
    required this.callData,
    required this.calleeName,
    this.calleeAvatarUrl,
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
            // Avatar
            FcAvatar(
              imageUrl: calleeAvatarUrl,
              initials: calleeName.isNotEmpty ? calleeName.substring(0, 1) : '?',
              size: 120,
              showBorder: true,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            // Nom
            Text(
              calleeName,
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            // Indicateur de sonnerie
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isVideo ? PhosphorIcons.videoCamera : PhosphorIcons.phone,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isVideo ? 'Appel vidéo en cours…' : 'Appel vocal en cours…',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            // Animation pulsante
            _PulsingDots(),
            const Spacer(flex: 3),
            // Bouton annuler
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      PhosphorIcons.phoneDisconnect,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Annuler',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// Animation de 3 points pulsants ("sonnerie en cours").
class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    // Démarre les animations avec un décalage
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _controllers.map((controller) {
        return AnimatedBuilder(
          animation: controller,
          builder: (_, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.3 + (controller.value * 0.7),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
