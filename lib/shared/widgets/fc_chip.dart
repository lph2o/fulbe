import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Reusable category/filter chip used across Directory, Marketplace, Jobs, Library.
class FcChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const FcChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? AppSpacing.stackMd : 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryContainer
                : AppColors.outlineVariant,
            width: isSelected ? 0 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: isSelected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrollable row of chips
class FcChipRow extends StatefulWidget {
  final List<String> labels;
  final int initialSelectedIndex;
  final ValueChanged<int>? onSelectionChanged;

  const FcChipRow({
    super.key,
    required this.labels,
    this.initialSelectedIndex = 0,
    this.onSelectionChanged,
  });

  @override
  State<FcChipRow> createState() => _FcChipRowState();
}

class _FcChipRowState extends State<FcChipRow> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile),
        itemCount: widget.labels.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.stackSm),
        itemBuilder: (context, index) {
          return FcChip(
            label: widget.labels[index],
            isSelected: _selectedIndex == index,
            onTap: () {
              setState(() => _selectedIndex = index);
              widget.onSelectionChanged?.call(index);
            },
          );
        },
      ),
    );
  }
}
