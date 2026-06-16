import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Écran de notifications (placeholder).
///
/// Affichera la liste des notifications push reçues (appels manqués,
/// nouveaux messages, mentions, etc.) une fois le backend de notifications
/// implémenté.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Notifications',
          style: AppTextStyles.headlineLgMobile.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            PhosphorIcons.arrowLeft,
            color: AppColors.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.bellSimple,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'Aucune notification',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Les nouvelles notifications apparaîtront ici.',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
