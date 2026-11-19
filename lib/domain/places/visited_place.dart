import '../../core/db/app_database.dart';

/// One unique location the user has been to, with all visits there.
class VisitedPlace {
  const VisitedPlace({
    required this.key,
    required this.name,
    required this.lat,
    required this.lng,
    required this.visits,
    this.placeId,
    this.address,
    this.nameSource,
  });

  /// Stable list key: place id, or `geo:lat,lng` for unlabelled clusters.
  final String key;
  final String? placeId;
  final String name;
  final String? address;
  final String? nameSource;
  final double lat;
  final double lng;
  final List<Visit> visits;

  int get visitCount => visits.length;

  int get lastVisitAt => visits.first.startAt;
}
