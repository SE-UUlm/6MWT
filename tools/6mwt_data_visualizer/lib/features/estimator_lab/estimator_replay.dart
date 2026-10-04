import 'dart:math' as math;

import 'package:six_minute_walk_test/core/domain/sensor_sample.dart' as app;
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/gps_step_distance_estimator.dart';

import '../../core/domain/haversine.dart';
import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';

/// Cumulative distance at an elapsed time, measured from the replay's first sample.
class DistancePoint {
  const DistancePoint(this.seconds, this.meters);
  final double seconds;
  final double meters;
}

/// One complete run; failed runs expose an error instead of a partial distance.
class ReplayResult {
  const ReplayResult(
    this.name,
    this.points, {
    this.error,
    this.additionalInfo = const {},
  });
  final String name;
  final List<DistancePoint> points;
  final String? error;
  final Map<String, String> additionalInfo;
  double? get distance =>
      error == null && points.isNotEmpty ? points.last.meters : null;

  /// Connect distance updates directly instead of plotting unchanged values after
  /// unrelated sensor events. Keep raw points for numerical replay comparisons.
  List<DistancePoint> get chartPoints {
    if (points.isEmpty) return const [];

    final updates = <DistancePoint>[points.first];
    for (final point in points.skip(1)) {
      if (point.meters != updates.last.meters) updates.add(point);
    }
    // Preserve the full recording window, including a stationary ending.
    if (updates.last.seconds != points.last.seconds) updates.add(points.last);
    return updates;
  }
}

/// Prepares one shared input stream for independently replaying several estimators.
/// Reference samples are used for comparison only and never enter that stream.
class EstimatorReplay {
  EstimatorReplay(Session session) {
    // Stable tie-breaking preserves file order for simultaneous events.
    final indexed = session.samples.indexed.toList();
    indexed.sort((a, b) {
      final order = a.$2.timestamp.compareTo(b.$2.timestamp);
      return order == 0 ? a.$1.compareTo(b.$1) : order;
    });
    // Adapt to the production model once. Read-only values prevent an experimental
    // estimator from changing the input seen by subsequent comparison runs.
    samples = List.unmodifiable(
      indexed.map((entry) {
        final s = entry.$2;
        return app.SensorSample(
          timestamp: s.timestamp,
          type: app.SampleType.fromWireName(s.type.wireName),
          sourceId: s.sourceId,
          values: Map.unmodifiable(s.values),
        );
      }),
    );
    start = samples.isEmpty ? session.startedAt : samples.first.timestamp;
    duration = samples.isEmpty
        ? 0
        : samples.last.timestamp.difference(start).inMicroseconds / 1e6;
    references = [
      for (var i = 0; i < session.references.length; i++)
        ReplayReference(
          session.referenceLabel(i),
          session.references[i].isManualReference,
          _referenceCurve(session.references[i], start, duration),
        ),
    ];
  }

  late final List<app.SensorSample> samples;
  late final DateTime start;
  late final double duration;

  /// Available overlap with the replay, or null if no valid overlap exists.
  late final List<ReplayReference> references;
  List<DistancePoint>? get reference => references.firstOrNull?.points;

  /// Runs synchronously using recorded timestamps, without wall-clock delays.
  ReplayResult run(DistanceEstimator estimator) {
    final name = estimator is GpsStepDistanceEstimator
        ? '${estimator.runtimeType} (GPS <= '
              '${estimator.maxGpsInterval.inMicroseconds / 1e6} s)'
        : estimator.runtimeType.toString();
    final points = <DistancePoint>[];
    try {
      estimator.reset();
      for (final sample in samples) {
        estimator.addSample(sample);
        final distance = estimator.totalDistance;
        if (!distance.isFinite || distance < 0) {
          throw StateError('Estimator returned an invalid distance: $distance');
        }
        final t = sample.timestamp.difference(start).inMicroseconds / 1e6;
        // Every event reaches the estimator, but the chart needs only the final
        // cumulative distance for events sharing the same timestamp.
        if (points.isNotEmpty && points.last.seconds == t) points.removeLast();
        points.add(DistancePoint(t, distance));
      }
      // Snapshot diagnostics: later resets must not change an earlier result.
      return ReplayResult(
        name,
        List.unmodifiable(points),
        additionalInfo: Map.unmodifiable(estimator.additionalInfo),
      );
    } catch (error) {
      // A broken experimental variant must not prevent other variants from running.
      return ReplayResult(name, const [], error: error.toString());
    }
  }
}

/// Clips the reference to its overlap with the replay, rebased to zero.
/// Missing boundaries are not extrapolated and do not hide the available track.
List<DistancePoint>? _referenceCurve(
  Session? reference,
  DateTime start,
  double duration,
) {
  if (reference == null || duration <= 0) return null;
  final positions = reference.positionSamples.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  if (positions.length < 2) return null;
  // Use a single distance source for the entire reference. Mixing cumulative
  // device distances and GPS segments could introduce jumps at missing values.
  final hasDistance = positions.every(
    (s) => s.values[PositionKeys.distance]?.isFinite ?? false,
  );
  final points = <DistancePoint>[];
  double cumulative = 0;
  SensorSample? previous;
  for (final sample in positions) {
    if (hasDistance) {
      cumulative = sample.values[PositionKeys.distance]!;
      if (points.isNotEmpty && cumulative < points.last.meters) return null;
    } else {
      final lat = sample.values[PositionKeys.latitude];
      final lon = sample.values[PositionKeys.longitude];
      if (lat == null ||
          lon == null ||
          !lat.isFinite ||
          !lon.isFinite ||
          lat.abs() > 90 ||
          lon.abs() > 180) {
        return null;
      }
      if (previous != null) {
        cumulative += haversineDistance(
          lat1: previous.values[PositionKeys.latitude]!,
          lon1: previous.values[PositionKeys.longitude]!,
          lat2: lat,
          lon2: lon,
        );
      }
    }
    final timestamp = sample.timestamp;
    final time = timestamp.difference(start).inMicroseconds / 1e6;
    if (points.isNotEmpty && points.last.seconds == time) points.removeLast();
    points.add(DistancePoint(time, cumulative));
    previous = sample;
  }
  final overlapStart = math.max(0.0, points.first.seconds);
  final overlapEnd = math.min(duration, points.last.seconds);
  if (overlapEnd <= overlapStart) return null;
  final baseline = interpolateDistance(points, overlapStart);
  return List.unmodifiable([
    DistancePoint(overlapStart, 0),
    for (final point in points)
      if (point.seconds > overlapStart && point.seconds < overlapEnd)
        DistancePoint(point.seconds, point.meters - baseline),
    DistancePoint(
      overlapEnd,
      interpolateDistance(points, overlapEnd) - baseline,
    ),
  ]);
}

/// Interpolates a nonempty curve with strictly increasing timestamps.
/// Outside its range, returns the nearest endpoint's distance.
double interpolateDistance(List<DistancePoint> points, double time) {
  if (time <= points.first.seconds) return points.first.meters;
  for (var i = 1; i < points.length; i++) {
    final right = points[i];
    if (time <= right.seconds) {
      final left = points[i - 1];
      final elapsedFraction =
          (time - left.seconds) / (right.seconds - left.seconds);
      return left.meters + (right.meters - left.meters) * elapsedFraction;
    }
  }
  return points.last.meters;
}

class ReplayReference {
  const ReplayReference(this.name, this.manual, this.points);
  final String name;
  final bool manual;
  final List<DistancePoint>? points;
  String get label => manual ? '$name (constant speed)' : name;
}
