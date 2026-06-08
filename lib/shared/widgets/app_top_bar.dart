import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import 'fc_card.dart';

/// Standard TopAppBar used on all authenticated screens.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? avatarUrl;
  final String title;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;

  const AppTopBar({
    super.key,
    this.avatarUrl,
    this.title = 'Fulɓe Connect',
    this.onAvatarTap,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppSpacing.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.marginMobile),
        child: GestureDetector(
          onTap: onAvatarTap,
          child: FcAvatar(
            imageUrl: avatarUrl ??
                'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80',
            size: AppSpacing.avatarMd,
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineLgMobile.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: onNotificationTap ?? () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.onSurfaceVariant,
            size: AppSpacing.iconMd,
          ),
          padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
        ),
      ],
    );
  }
}
