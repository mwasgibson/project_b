import 'dart:math' as math;

/// Pure helpers for matching visits to known places (haversine radius).
class PlaceMatch {
  const PlaceMatch._();

  /// Great-circle distance in metres.
  static double haversineM(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dp = (lat2 - lat1) * math.pi / 180;
    final dl = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Best candidate within [radiusM], or null.
  static T? nearestWithin<T>({
    required double lat,
    required double lng,
    required Iterable<T> candidates,
    required double Function(T) candidateLat,
    required double Function(T) candidateLng,
    required int Function(T) candidateRadiusM,
    double defaultRadiusM = 100,
  }) {
    T? best;
    var bestD = double.infinity;
    for (final c in candidates) {
      final radius = candidateRadiusM(c).toDouble();
      final limit = radius > 0 ? radius : defaultRadiusM;
      final d = haversineM(lat, lng, candidateLat(c), candidateLng(c));
      if (d <= limit && d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  /// Prefer a short, human name from structured placemark fields.
  static String displayName({
    String? name,
    String? street,
    String? subLocality,
    String? locality,
    String? subAdministrativeArea,
    String? administrativeArea,
  }) {
    final candidates = [
      name,
      street,
      subLocality,
      locality,
      subAdministrativeArea,
      administrativeArea,
    ];
    for (final c in candidates) {
      final t = c?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return 'Unknown place';
  }

  static String? displayAddress({
    String? street,
    String? subLocality,
    String? locality,
    String? administrativeArea,
    String? country,
  }) {
    final parts = <String>[
      if (street != null && street.trim().isNotEmpty) street.trim(),
      if (subLocality != null && subLocality.trim().isNotEmpty)
        subLocality.trim(),
      if (locality != null && locality.trim().isNotEmpty) locality.trim(),
      if (administrativeArea != null && administrativeArea.trim().isNotEmpty)
        administrativeArea.trim(),
      if (country != null && country.trim().isNotEmpty) country.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}
