import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'distance_estimator.dart';

/// Experimental, causal GPS filter. Rejected fixes never become the anchor.
class FilteredGpsEstimator extends DistanceEstimator {
  FilteredGpsEstimator({required this.maxAccuracy, required this.maxSpeed});

  /// Largest accepted reported GPS accuracy radius, in meters.
  final double maxAccuracy;

  /// Largest accepted speed between successive accepted fixes, in meters/second.
  final double maxSpeed;
  SensorSample? _previous;
  double _distance = 0;
  int rejected = 0;

  @override
  Map<String, String> get additionalInfo => {
    'Rejected GPS': '$rejected',
    'Max accuracy': '$maxAccuracy m',
    'Max speed': '$maxSpeed m/s',
  };

  @override
  double get totalDistance => _distance;

  @override
  void addSample(SensorSample sample) {
    if (sample.type != SampleType.position) return;
    final lat = sample.values[PositionKeys.latitude];
    final lon = sample.values[PositionKeys.longitude];
    final accuracy = sample.values[PositionKeys.accuracy];

    // Missing accuracy is allowed; explicitly invalid or poor accuracy is not.
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180 ||
        (accuracy != null &&
            (!accuracy.isFinite || accuracy < 0 || accuracy > maxAccuracy))) {
      rejected++;
      return;
    }
    final previous = _previous;
    if (previous != null) {
      final seconds =
          sample.timestamp.difference(previous.timestamp).inMicroseconds / 1e6;
      final distance = Geolocator.distanceBetween(
        previous.values[PositionKeys.latitude]!,
        previous.values[PositionKeys.longitude]!,
        lat,
        lon,
      );
      if (seconds <= 0 || distance / seconds > maxSpeed) {
        // Keep the last accepted anchor so an outlier cannot create two jumps.
        rejected++;
        return;
      }
      _distance += distance;
    }
    // The first accepted fix establishes the anchor without adding distance.
    _previous = sample;
  }

  @override
  void reset() {
    _previous = null;
    _distance = 0;
    rejected = 0;
  }
}

/// Uses the first cumulative-step source; counter resets establish a new baseline.
class StepDistanceEstimator extends DistanceEstimator {
  StepDistanceEstimator({required this.stepLength});

  /// Fixed distance per step in meters; no reference-based calibration is used.
  final double stepLength;
  String? _source;
  double? _previous;
  double _distance = 0;

  @override
  Map<String, String> get additionalInfo => {
    'Step length': '$stepLength m',
    'Step source': _source ?? 'No step samples',
  };

  @override
  double get totalDistance => _distance;

  @override
  void addSample(SensorSample sample) {
    if (sample.type != SampleType.steps) return;
    final count = sample.values[StepKeys.cumulativeSteps];
    if (count == null || !count.isFinite || count < 0) return;

    // Counters from different devices have independent baselines. Mixing them
    // would count the same walk twice or introduce artificial counter jumps.
    _source ??= sample.sourceId;
    if (sample.sourceId != _source) return;
    final previous = _previous;
    if (previous != null && count >= previous) {
      _distance += (count - previous) * stepLength;
    }
    // A lower counter starts a new baseline; it cannot subtract walked distance.
    _previous = count;
  }

  @override
  void reset() {
    _source = null;
    _previous = null;
    _distance = 0;
  }
}
