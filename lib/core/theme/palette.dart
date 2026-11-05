import 'package:flutter/material.dart';

/// Colour tokens from docs/04-design-brief.md.
/// Contrast ratios were checked against WCAG 2.1 (text 4.5:1, UI 3:1);
/// test/core/theme/palette_contrast_test.dart keeps them honest.
@immutable
class PaletteSet {
  const PaletteSet({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.visit,
    required this.trip,
    required this.gap,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color background;

  /// Cards, bars and sheets.
  final Color surface;

  /// Chips and inputs.
  final Color surfaceVariant;

  /// Soft dividers (decorative only; never the sole boundary of a control).
  final Color outline;

  /// Borders of interactive controls (at least 3:1 against surfaces).
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color visit;
  final Color trip;
  final Color gap;
  final Color success;
  final Color warning;
  final Color error;
}

abstract final class AppPalette {
  static const light = PaletteSet(
    brightness: Brightness.light,
    primary: Color(0xFF0F766E),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F2F1),
    outline: Color(0xFFE2E6E4),
    outlineStrong: Color(0xFF7C8885),
    textPrimary: Color(0xFF12171A),
    textSecondary: Color(0xFF5B6663),
    visit: Color(0xFF0F766E),
    trip: Color(0xFF3B82F6),
    gap: Color(0xFFC9CFCD),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    error: Color(0xFFB91C1C),
  );

  static const dark = PaletteSet(
    brightness: Brightness.dark,
    primary: Color(0xFF2DD4BF),
    onPrimary: Color(0xFF042F2E),
    background: Color(0xFF0C0F10),
    surface: Color(0xFF151A1C),
    surfaceVariant: Color(0xFF1E2528),
    outline: Color(0xFF2A3236),
    outlineStrong: Color(0xFF6E7B80),
    textPrimary: Color(0xFFECF0EF),
    textSecondary: Color(0xFF9AA5A2),
    visit: Color(0xFF2DD4BF),
    trip: Color(0xFF60A5FA),
    gap: Color(0xFF3A4347),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
  );
}
