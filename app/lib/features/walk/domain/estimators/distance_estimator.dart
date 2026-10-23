import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

import 'distance_confidence.dart';

// Turns a stream of positions into a walked distance. Implementations can use
// different strategies (GPS, step-based, sensor fusion) interchangeably.
abstract class DistanceEstimator {
  double get totalDistance;

  /// Human-readable diagnostics for development tools, read after a calculation.
  /// Implementations can report counters or settings; reset must clear run state.
  Map<String, String> get additionalInfo => const {};

  /// Trust in [totalDistance], or null if the estimator does not assess it.
  DistanceConfidence? get confidence => null;

  /// Supplies optional profile data before a new run. Fixed comparison
  /// estimators keep their configured parameters unless they override this.
  void configureProfile({num? heightCm, String? gender}) {}

  void addSample(SensorSample sample);

  void reset();
}

class GpsDistanceEstimator extends DistanceEstimator {
  /// Only rates jitter for confidence; implausible segments still count.
  static const plausibleSpeed = 4.0;

  SensorSample? _previous;
  double _totalDistance = 0;
  double _accuracySum = 0;
  int _segments = 0;
  int _implausibleSegments = 0;

  @override
  double get totalDistance => _totalDistance;

  /// Unfiltered jumps are not removed, so they lower the GPS quality instead.
  @override
  DistanceConfidence get confidence => ConfidenceHeuristics.combine(
    total: _totalDistance,
    gpsDistance: _totalDistance,
    gpsQuality: ConfidenceHeuristics.gpsQuality(
      accuracySum: _accuracySum,
      accepted: _segments - _implausibleSegments,
      rejected: _implausibleSegments,
    ),
    otherQuality: 0,
  );

  // Adds a new position and calculates the distance from the previous position.
  @override
  void addSample(SensorSample sample) {
    if (sample.type != SampleType.position) {
      return;
    }

    final latitude = sample.values[PositionKeys.latitude];
    final longitude = sample.values[PositionKeys.longitude];

    if (latitude == null || longitude == null) {
      return;
    }

    final previous = _previous;

    if (previous != null) {
      final distance = Geolocator.distanceBetween(
        previous.values[PositionKeys.latitude]!,
        previous.values[PositionKeys.longitude]!,
        latitude,
        longitude,
      );

      _totalDistance += distance;

      final seconds =
          sample.timestamp.difference(previous.timestamp).inMicroseconds / 1e6;
      final accuracy = sample.values[PositionKeys.accuracy];
      _segments++;
      _accuracySum += accuracy != null && accuracy.isFinite && accuracy >= 0
          ? accuracy
          : ConfidenceHeuristics.missingGpsAccuracy;
      if (seconds <= 0 || distance / seconds > plausibleSpeed) {
        _implausibleSegments++;
      }
    }

    _previous = sample;
  }

  @override
  void reset() {
    _previous = null;
    _totalDistance = 0;
    _accuracySum = 0;
    _segments = 0;
    _implausibleSegments = 0;
  }
}
