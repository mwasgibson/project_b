import 'package:flutter_test/flutter_test.dart';
import 'package:project_b/domain/segmentation/segmenter.dart';

void main() {
  const segmenter = Segmenter();

  PointInput p(int id, int minutes, double lat, double lng) => PointInput(
        id: id,
        recordedAt: DateTime.utc(2026, 11, 16, 10, minutes).millisecondsSinceEpoch,
        utcOffsetMin: 180,
        lat: lat,
        lng: lng,
      );

  test('empty input yields nothing', () {
    final r = segmenter.run(const []);
    expect(r.visits, isEmpty);
    expect(r.trips, isEmpty);
  });

  test('stationary cluster over 10 minutes becomes a visit', () {
    // Same spot every 2 minutes for 12 minutes.
    final points = [
      for (var m = 0; m <= 12; m += 2) p(m, m, -1.2864, 36.8172),
    ];
    final r = segmenter.run(points);
    expect(r.visits, hasLength(1));
    expect(r.visits.first.pointCount, points.length);
    expect(r.processedPointIds, hasLength(points.length));
  });

  test('short stop under 10 minutes is not a visit yet', () {
    final points = [
      for (var m = 0; m <= 6; m += 2) p(m, m, -1.2864, 36.8172),
    ];
    final r = segmenter.run(points);
    expect(r.visits, isEmpty);
  });

  test('two visits with movement between yield a trip', () {
    final points = [
      // Visit A ~12 min
      for (var m = 0; m <= 12; m += 2) p(m, m, -1.2864, 36.8172),
      // Move ~500 m north and stay 12 min
      for (var m = 20; m <= 32; m += 2) p(100 + m, m, -1.2819, 36.8172),
    ];
    final r = segmenter.run(points);
    expect(r.visits, hasLength(2));
    expect(r.trips, hasLength(1));
    expect(r.trips.first.distanceM, greaterThan(400));
  });
}
