/// Result of reverse geocoding one coordinate pair.
class ResolvedPlace {
  const ResolvedPlace({
    required this.name,
    this.address,
    this.category,
    this.lat,
    this.lng,
  });

  /// Short label for the timeline (e.g. "Westlands" or "Java House").
  final String name;

  /// Longer line when available (street + locality).
  final String? address;

  /// Optional coarse type from the provider (e.g. locality, street).
  final String? category;

  /// Provider centroid if different from the query; else null.
  final double? lat;
  final double? lng;
}

/// Failure modes for reverse geocoding (docs/05 label_state).
enum PlaceResolveFailure {
  /// Auto-labelling is off in settings.
  disabled,

  /// OS geocoder unavailable or rate-limited.
  unavailable,

  /// No result for these coordinates.
  notFound,

  /// Network / platform error; worth retrying later.
  transient,
}

class PlaceResolveException implements Exception {
  const PlaceResolveException(this.failure, [this.message]);

  final PlaceResolveFailure failure;
  final String? message;

  @override
  String toString() => 'PlaceResolveException($failure${message == null ? '' : ': $message'})';
}

/// Boundary around the OS / offline geocoder (docs/02).
///
/// UI and labelling depend only on this interface so the backend can move from
/// platform geocoding to Google Places or an offline pack without UI changes.
abstract interface class PlaceResolver {
  /// Reverse-geocode [lat],[lng]. Throws [PlaceResolveException] on failure.
  Future<ResolvedPlace> resolve(double lat, double lng);
}
