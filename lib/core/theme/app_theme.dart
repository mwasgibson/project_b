import 'package:flutter/material.dart';

import 'domain_colors.dart';
import 'palette.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  /// Corner radii from docs/04: 12 cards, 16 sheets, pill chips.
  static const double radiusCard = 12;
  static const double radiusSheet = 16;

  static ThemeData _build(PaletteSet p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      error: p.error,
      onError: p.brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF2B0A0A),
      surface: p.background,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerHighest: p.surfaceVariant,
      outline: p.outlineStrong,
      outlineVariant: p.outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
    );

    // Type scale from docs/04: 28 / 22 / 18 / 16 / 14 / 12.
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall
          ?.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: base.textTheme.titleMedium
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16),
      labelLarge: base.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12),
    );

    return base.copyWith(
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[DomainColors.from(p)],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: p.outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.outline, space: 1, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.surfaceVariant,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          text.bodySmall?.copyWith(color: p.textPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: BorderSide(color: p.outlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: BorderSide(color: p.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceVariant,
        side: BorderSide(color: p.outline),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(color: p.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        subtitleTextStyle:
            text.bodyMedium?.copyWith(color: p.textSecondary, fontSize: 14),
      ),
    );
  }
}
