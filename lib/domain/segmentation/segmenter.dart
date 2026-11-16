import 'dart:math' as math;

/// Tunable thresholds (docs/02). Exposed for tests and later settings.
class SegmenterConfig {
  const SegmenterConfig({
    this.visitRadiusM = 100,
    this.minVisitDuration = const Duration(minutes: 10),
    this.minTripDistanceM = 50,
  });

  final double visitRadiusM;
  final Duration minVisitDuration;
  final double minTripDistanceM;
}

class PointInput {
  const PointInput({
    required this.id,
    required this.recordedAt,
    required this.utcOffsetMin,
    required this.lat,
    required this.lng,
  });

  final int id;
  final int recordedAt;
  final int utcOffsetMin;
  final double lat;
  final double lng;
}

class VisitDraft {
  const VisitDraft({
    required this.startAt,
    required this.endAt,
    required this.utcOffsetMin,
    required this.lat,
    required this.lng,
    required this.pointCount,
    required this.pointIds,
  });

  final int startAt;
  final int endAt;
  final int utcOffsetMin;
  final double lat;
  final double lng;
  final int pointCount;
  final List<int> pointIds;
}

class TripDraft {
  const TripDraft({
    required this.startAt,
    required this.endAt,
    required this.utcOffsetMin,
    required this.distanceM,
    required this.fromVisitIndex,
    required this.toVisitIndex,
  });

  final int startAt;
  final int endAt;
  final int utcOffsetMin;
  final double distanceM;
  final int fromVisitIndex;
  final int toVisitIndex;
}

class SegmenterResult {
  const SegmenterResult({
    required this.visits,
    required this.trips,
    required this.processedPointIds,
  });

  final List<VisitDraft> visits;
  final List<TripDraft> trips;
  final List<int> processedPointIds;
}

/// Pure segmenter: raw points → visits + trips (docs/02).
class Segmenter {
  const Segmenter({this.config = const SegmenterConfig()});

  final SegmenterConfig config;

  SegmenterResult run(List<PointInput> points) {
    if (points.isEmpty) {
      return const SegmenterResult(
        visits: [],
        trips: [],
        processedPointIds: [],
      );
    }

    final sorted = [...points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final visits = <VisitDraft>[];
    final processed = <int>[];

    var i = 0;
    while (i < sorted.length) {
      final cluster = <PointInput>[sorted[i]];
      var j = i + 1;
      while (j < sorted.length) {
        final cLat = _mean(cluster.map((p) => p.lat));
        final cLng = _mean(cluster.map((p) => p.lng));
        if (_haversineM(cLat, cLng, sorted[j].lat, sorted[j].lng) <=
            config.visitRadiusM) {
          cluster.add(sorted[j]);
          j++;
        } else {
          break;
        }
      }

      final startAt = cluster.first.recordedAt;
      final endAt = cluster.last.recordedAt;
      final durationMs = endAt - startAt;

      if (durationMs >= config.minVisitDuration.inMilliseconds &&
          cluster.length >= 2) {
        visits.add(
          VisitDraft(
            startAt: startAt,
            endAt: endAt,
            utcOffsetMin: cluster.first.utcOffsetMin,
            lat: _mean(cluster.map((p) => p.lat)),
            lng: _mean(cluster.map((p) => p.lng)),
            pointCount: cluster.length,
            pointIds: cluster.map((p) => p.id).toList(),
          ),
        );
        processed.addAll(cluster.map((p) => p.id));
      }
      // Non-visit clusters stay unprocessed until more points arrive or
      // end-of-day pass with lower thresholds (later).

      i = j > i ? j : i + 1;
    }

    final trips = <TripDraft>[];
    for (var v = 0; v < visits.length - 1; v++) {
      final a = visits[v];
      final b = visits[v + 1];
      final distance = _haversineM(a.lat, a.lng, b.lat, b.lng);
      if (distance < config.minTripDistanceM) continue;
      if (b.startAt <= a.endAt) continue;
      trips.add(
        TripDraft(
          startAt: a.endAt,
          endAt: b.startAt,
          utcOffsetMin: a.utcOffsetMin,
          distanceM: distance,
          fromVisitIndex: v,
          toVisitIndex: v + 1,
        ),
      );
    }

    return SegmenterResult(
      visits: visits,
      trips: trips,
      processedPointIds: processed,
    );
  }

  static double _mean(Iterable<double> values) {
    var sum = 0.0;
    var n = 0;
    for (final v in values) {
      sum += v;
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }

  /// Great-circle distance in metres.
  static double _haversineM(
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
}
