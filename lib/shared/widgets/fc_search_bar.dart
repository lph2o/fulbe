import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Standard search bar used across all screens.
class FcSearchBar extends StatelessWidget {
  final String placeholder;
  final bool showFilterButton;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;

  const FcSearchBar({
    super.key,
    required this.placeholder,
    this.showFilterButton = false,
    this.onFilterTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: TextField(
              onChanged: onChanged,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.outline),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.outline,
                  size: AppSpacing.iconMd,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                isDense: true,
              ),
            ),
          ),
        ),
        if (showFilterButton) ...[
          const SizedBox(width: AppSpacing.stackSm),
          _FilterButton(onTap: onFilterTap),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _FilterButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: AppColors.outlineVariant, width: 0.8),
        ),
        child: const Icon(
          Icons.tune,
          color: AppColors.onSurfaceVariant,
          size: AppSpacing.iconMd,
        ),
      ),
    );
  }
}
