import 'package:geocoding/geocoding.dart' as geo;

import '../../../domain/places/place_match.dart';
import '../../../domain/places/place_resolver.dart';

/// Reverse geocoding via the OS geocoder (`geocoding` package).
///
/// Android uses [android.location.Geocoder]; iOS uses CLGeocoder.
/// May contact the vendor backend — disclosed in settings (docs/02).
class PlatformPlaceResolver implements PlaceResolver {
  PlatformPlaceResolver({geo.Geocoding? client}) : _client = client ?? geo.Geocoding();

  final geo.Geocoding _client;

  @override
  Future<ResolvedPlace> resolve(double lat, double lng) async {
    try {
      final marks = await _client.placemarkFromCoordinates(lat, lng);
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
    } on geo.NoResultFoundException {
      throw const PlaceResolveException(PlaceResolveFailure.notFound);
    } catch (e) {
      final msg = e.toString();
      // Platform rate limits often surface as IO_ERROR.
      if (msg.contains('IO_ERROR') || msg.contains('network')) {
        throw PlaceResolveException(PlaceResolveFailure.transient, msg);
      }
      throw PlaceResolveException(PlaceResolveFailure.unavailable, msg);
    }
  }
}
