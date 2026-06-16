import 'package:flutter/material.dart';

/// Fulɓe Connect Premium Design System
/// Inspired by LinkedIn Premium, Stripe, Airbnb, Linear.
abstract class AppColors {
  // ── Primary (Deep Emerald Green) ──────────────────────────────────────
  static const Color primary = Color(0xFF0D7A4E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0D7A4E);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color inversePrimary = Color(0xFF91D5B1);
  static const Color primaryFixed = Color(0xFFE8F5EE);
  static const Color primaryFixedDim = Color(0xFFC3E8D3);
  static const Color onPrimaryFixed = Color(0xFF002114);
  static const Color onPrimaryFixedVariant = Color(0xFF0D7A4E);

  // ── Secondary (Gold Sand) ────────────────────────────────────────────
  static const Color secondary = Color(0xFFC9A84C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFC9A84C);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFFFBF5E8);
  static const Color secondaryFixedDim = Color(0xFFF0E1B8);
  static const Color onSecondaryFixed = Color(0xFF241A00);
  static const Color onSecondaryFixedVariant = Color(0xFF8B7323);

  // ── Tertiary (Electric Blue) ─────────────────────────────────────────
  static const Color tertiary = Color(0xFF3B82F6);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF3B82F6);
  static const Color onTertiaryContainer = Color(0xFFFFFFFF);
  static const Color tertiaryFixed = Color(0xFFE8F0FB);
  static const Color tertiaryFixedDim = Color(0xFFBFD9FC);
  static const Color onTertiaryFixed = Color(0xFF001D32);
  static const Color onTertiaryFixedVariant = Color(0xFF2563EB);

  // ── Surface ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFEEEDE8);
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFF7F6F2);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE8E6E0);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F6F2);
  static const Color surfaceContainer = Color(0xFFF0EFEA);
  static const Color surfaceContainerHigh = Color(0xFFE8E6E0);
  static const Color surfaceContainerHighest = Color(0xFFE0DED7);
  static const Color surfaceVariant = Color(0xFFE8E6E0);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF888888);
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);

  // ── Outline ──────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF888888);
  static const Color outlineVariant = Color(0xFFDDDDDD);

  // ── Error ────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Misc ─────────────────────────────────────────────────────────────
  static const Color surfaceTint = Color(0xFF0D7A4E);

  // ── Legacy compatibility aliases ─────────────────────────────────────
  /// Legacy dark green — use [primary] (emerald) for new designs.
  static const Color forestGreen = Color(0xFF012D1D);
  /// Legacy dark gold — use [secondary] (gold sand) for new designs.
  static const Color softGold = Color(0xFF735C00);
  // ── Purple ───────────────────────────────────────────────────────────
  /// Purple accent for heritage/library sections.
  static const Color purple = Color(0xFF7C3AED);
  /// Light purple background for purple-tinted cards.
  static const Color purpleFixed = Color(0xFFF2EDF8);
  /// Dim light purple for Discussion cards.
  static const Color purpleFixedDim = Color(0xFFEDE9FE);

  // ── Teal ─────────────────────────────────────────────────────────────
  /// Teal accent for map/world sections.
  static const Color teal = Color(0xFF0891B2);
  /// Light teal background for map cards.
  static const Color tealFixed = Color(0xFFCFFAFE);

  // ── Gold ─────────────────────────────────────────────────────────────
  /// Light gold background for marketplace cards.
  static const Color goldFixed = Color(0xFFFEF9C3);

  // ── Green ────────────────────────────────────────────────────────────
  /// Light green background for finances cards.
  static const Color greenFixed = Color(0xFFDCFCE7);

  // ── Blue ─────────────────────────────────────────────────────────────
  /// Light blue background for learning cards.
  static const Color blueFixed = Color(0xFFDBEAFE);
}
