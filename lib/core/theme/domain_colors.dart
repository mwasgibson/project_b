import 'package:flutter/material.dart';

import 'palette.dart';

/// Colours that Material's [ColorScheme] has no slot for.
@immutable
class DomainColors extends ThemeExtension<DomainColors> {
  const DomainColors({
    required this.visit,
    required this.trip,
    required this.gap,
    required this.success,
    required this.warning,
  });

  factory DomainColors.from(PaletteSet p) => DomainColors(
        visit: p.visit,
        trip: p.trip,
        gap: p.gap,
        success: p.success,
        warning: p.warning,
      );

  final Color visit;
  final Color trip;
  final Color gap;
  final Color success;
  final Color warning;

  @override
  DomainColors copyWith({
    Color? visit,
    Color? trip,
    Color? gap,
    Color? success,
    Color? warning,
  }) =>
      DomainColors(
        visit: visit ?? this.visit,
        trip: trip ?? this.trip,
        gap: gap ?? this.gap,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  DomainColors lerp(ThemeExtension<DomainColors>? other, double t) {
    if (other is! DomainColors) return this;
    return DomainColors(
      visit: Color.lerp(visit, other.visit, t)!,
      trip: Color.lerp(trip, other.trip, t)!,
      gap: Color.lerp(gap, other.gap, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension DomainColorsContext on BuildContext {
  DomainColors get domainColors => Theme.of(this).extension<DomainColors>()!;
}
