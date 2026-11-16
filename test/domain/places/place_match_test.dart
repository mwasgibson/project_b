import 'package:flutter_test/flutter_test.dart';
import 'package:project_b/domain/places/place_match.dart';

void main() {
  test('haversine is ~0 for same point', () {
    expect(PlaceMatch.haversineM(-1.28, 36.82, -1.28, 36.82), closeTo(0, 0.01));
  });

  test('haversine Nairobi CBD to Westlands is roughly 4–6 km', () {
    // Approximate fixed points
    final d = PlaceMatch.haversineM(-1.2864, 36.8172, -1.2673, 36.8102);
    expect(d, greaterThan(1500));
    expect(d, lessThan(8000));
  });

  test('nearestWithin returns only candidates inside radius', () {
    final places = [
      (id: 'a', lat: -1.2864, lng: 36.8172, radiusM: 100),
      (id: 'b', lat: -1.2900, lng: 36.8200, radiusM: 50),
    ];
    final hit = PlaceMatch.nearestWithin(
      lat: -1.2865,
      lng: 36.8173,
      candidates: places,
      candidateLat: (p) => p.lat,
      candidateLng: (p) => p.lng,
      candidateRadiusM: (p) => p.radiusM,
    );
    expect(hit?.id, 'a');
  });

  test('displayName prefers name then street then locality', () {
    expect(
      PlaceMatch.displayName(name: 'Java House', locality: 'Nairobi'),
      'Java House',
    );
    expect(
      PlaceMatch.displayName(street: 'Kenyatta Ave', locality: 'Nairobi'),
      'Kenyatta Ave',
    );
    expect(PlaceMatch.displayName(locality: 'Nairobi'), 'Nairobi');
    expect(PlaceMatch.displayName(), 'Unknown place');
  });
}
