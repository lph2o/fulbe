import 'package:flutter/material.dart';

/// Heritage Modernism — Typography System
/// Based on Inter font family with a structured scale.
abstract class AppTextStyles {
  // Display
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 56 / 48,
    letterSpacing: -0.02 * 48,
    decoration: TextDecoration.none,
  );

  // Headlines
  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    decoration: TextDecoration.none,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    decoration: TextDecoration.none,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    decoration: TextDecoration.none,
  );

  // Labels
  static const TextStyle labelLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0.01 * 14,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
    decoration: TextDecoration.none,
  );
}
