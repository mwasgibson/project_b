import 'package:geocoding/geocoding.dart' as geo;

import '../../../domain/places/place_match.dart';
import '../../../domain/places/place_resolver.dart';

/// Reverse geocoding via the OS geocoder (`geocoding` package).
///
/// Android uses Geocoder; iOS uses CLGeocoder.
/// May contact the vendor backend — disclosed in settings (docs/02).
///
/// Uses the stable top-level [geo.placemarkFromCoordinates] API (v3+).
class PlatformPlaceResolver implements PlaceResolver {
  @override
  Future<ResolvedPlace> resolve(double lat, double lng) async {
    try {
      final marks = await geo.placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) {
        throw const PlaceResolveException(PlaceResolveFailure.notFound);
      }
      final p = marks.first;
      final name = PlaceMatch.displayName(
        name: p.name,
        street: p.street,
        subLocality: p.subLocality,
        locality: p.locality,
        subAdministrativeArea: p.subAdministrativeArea,
        administrativeArea: p.administrativeArea,
      );
      if (name == 'Unknown place') {
        throw const PlaceResolveException(PlaceResolveFailure.notFound);
      }
      final address = PlaceMatch.displayAddress(
        street: p.street,
        subLocality: p.subLocality,
        locality: p.locality,
        administrativeArea: p.administrativeArea,
        country: p.country,
      );
      return ResolvedPlace(
        name: name,
        address: address,
        category: p.thoroughfare != null && p.thoroughfare!.isNotEmpty
            ? 'street'
            : (p.locality != null ? 'locality' : null),
      );
    } on PlaceResolveException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('IO_ERROR') ||
          msg.contains('network') ||
          msg.contains('SocketException')) {
        throw PlaceResolveException(PlaceResolveFailure.transient, msg);
      }
      if (msg.contains('No result') || msg.contains('not found')) {
        throw const PlaceResolveException(PlaceResolveFailure.notFound);
      }
      throw PlaceResolveException(PlaceResolveFailure.unavailable, msg);
    }
  }
}
