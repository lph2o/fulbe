import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// Heritage Modernism — Full MaterialApp ThemeData
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          tertiaryContainer: AppColors.tertiaryContainer,
          onTertiaryContainer: AppColors.onTertiaryContainer,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
          inverseSurface: AppColors.inverseSurface,
          onInverseSurface: AppColors.inverseOnSurface,
          inversePrimary: AppColors.inversePrimary,
          surfaceTint: AppColors.surfaceTint,
        ),
        scaffoldBackgroundColor: AppColors.background,
        // ── AppBar ──────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface.withValues(alpha: 0.9),
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          centerTitle: true,
          titleTextStyle: AppTextStyles.headlineLgMobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
        ),
        // ── Navigation Bar (bottom) ──────────────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          height: AppSpacing.bottomNavHeight,
          indicatorColor: AppColors.secondaryContainer.withValues(alpha: 0.6),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelSm
                  .copyWith(color: AppColors.primaryContainer);
            }
            return AppTextStyles.labelSm
                .copyWith(color: AppColors.onSurfaceVariant);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                  color: AppColors.primaryContainer, size: 24);
            }
            return const IconThemeData(
                color: AppColors.onSurfaceVariant, size: 24);
          }),
        ),
        // ── Elevated Button ──────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            textStyle: AppTextStyles.labelMd.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ── Outlined Button ──────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryContainer,
            side: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            textStyle: AppTextStyles.labelMd.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ── Text Button ──────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: AppTextStyles.labelMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // ── Card ─────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.surfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: const BorderSide(color: AppColors.outlineVariant, width: 0.8),
          ),
          margin: EdgeInsets.zero,
        ),
        // ── Input Decoration ─────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            borderSide: const BorderSide(
                color: AppColors.primaryContainer, width: 1.5),
          ),
          hintStyle:
              AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        // ── Divider ──────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.outlineVariant,
          thickness: 0.8,
          space: 0,
        ),
        // ── Chip ─────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceContainerLow,
          selectedColor: AppColors.secondaryContainer,
          side: const BorderSide(color: AppColors.outlineVariant, width: 0.8),
          shape: const StadiumBorder(),
          labelStyle: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      );
}
