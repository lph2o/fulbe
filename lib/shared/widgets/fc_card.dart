import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Standard avatar with network image + fallback initials
class FcAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;

  const FcAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppSpacing.avatarMd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 0.8),
        color: AppColors.surfaceContainerHigh,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Initials(initials: initials, size: size),
            )
          : _Initials(initials: initials, size: size),
    );
  }
}

class _Initials extends StatelessWidget {
  final String? initials;
  final double size;
  const _Initials({this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryFixed,
      child: Center(
        child: Text(
          initials ?? '?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimaryFixed,
          ),
        ),
      ),
    );
  }
}

/// Standard content card with soft shadow and border
class FcCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const FcCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = AppSpacing.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.outlineVariant, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(AppSpacing.stackMd),
          child: child,
        ),
      ),
    );
  }
}
