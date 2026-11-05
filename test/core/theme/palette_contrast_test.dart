import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_b/core/theme/palette.dart';

/// WCAG 2.1 contrast ratio between two colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final entry in {
    'light': AppPalette.light,
    'dark': AppPalette.dark,
  }.entries) {
    final name = entry.key;
    final p = entry.value;

    group('$name palette', () {
      test('body text is at least 4.5:1 on background and surfaces', () {
        expect(contrast(p.textPrimary, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textPrimary, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textSecondary, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textSecondary, p.surface), greaterThanOrEqualTo(4.5));
        expect(
          contrast(p.textSecondary, p.surfaceVariant),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('primary and its on-colour are readable', () {
        expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(p.primary, p.background), greaterThanOrEqualTo(3));
        expect(contrast(p.primary, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('status colours are readable as text on surface', () {
        expect(contrast(p.success, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.warning, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.error, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('control borders and map lines are at least 3:1', () {
        expect(contrast(p.outlineStrong, p.background), greaterThanOrEqualTo(3));
        expect(contrast(p.outlineStrong, p.surface), greaterThanOrEqualTo(3));
        expect(contrast(p.trip, p.surface), greaterThanOrEqualTo(3));
        expect(contrast(p.visit, p.surface), greaterThanOrEqualTo(3));
      });
    });
  }
}
