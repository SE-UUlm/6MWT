import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

import 'distance_estimator.dart';

/// GPS distance with a phone-step fallback and a session-local stride estimate.
///
/// Sensor timestamps define the intervals, not callback arrival order. Batched
/// steps are distributed uniformly over their interval because the phone does
/// not report individual step timestamps. GPS replaces only the overlapping
/// portion, so recovery and delayed callbacks cannot count the same time twice.
class GpsStepDistanceEstimator extends DistanceEstimator {
  GpsStepDistanceEstimator({
    required this.stepSourceId,
    this.gpsFallbackTimeout = maxGpsGap,
    this.maxGpsInterval = maxGpsGap,
  }) {
    if (gpsFallbackTimeout <= Duration.zero ||
        maxGpsInterval <= Duration.zero) {
      throw ArgumentError('GPS time limits must be positive.');
    }
  }

  final String stepSourceId;

  /// Wait this long after a good fix before counting uncovered steps.
  final Duration gpsFallbackTimeout;

  /// Accept GPS segments up to this duration, including after fallback starts.
  /// Accepted GPS replaces overlapping step distance and can train the stride.
  final Duration maxGpsInterval;

  // Conservative algorithm defaults, in metres and seconds. These are tuning
  // parameters, not guarantees about the accuracy of a phone's sensors.
  static const defaultStepLength = 0.7;
  static const maxStepLength = 1.5;
  static const maxGpsAccuracy = 10.0;
  static const maxGpsSpeed = 3.0;
  static const maxGpsGap = Duration(seconds: 5);
  static const minCalibrationTime = Duration(seconds: 15);
  static const minCalibrationSteps = 10;
  static const minCalibrationDistance = 10.0;
  static const smoothingFactor = 0.2;

  final _gpsIntervals = <_GpsInterval>[];
  final _stepIntervals = <_StepInterval>[];
  SensorSample? _gpsAnchor;
  DateTime? _lastGpsTime;
  DateTime? _lastStepTime;
  DateTime? _latestTime;
  double? _lastSteps;
  double _gpsDistance = 0;
  double _totalDistance = 0;
  double? _learnedStepLength;
  int _acceptedGpsIntervals = 0;
  int _rejectedGpsGap = 0;
  int _rejectedGpsCoordinates = 0;
  int _rejectedGpsAccuracy = 0;
  int _rejectedGpsSpeed = 0;
  int _calibrationUpdates = 0;
  int _rejectedCalibration = 0;

  DateTime? _calibrationEnd;
  Duration _calibrationTime = Duration.zero;
  double _calibrationSteps = 0;
  double _calibrationDistance = 0;

  @override
  double get totalDistance => _totalDistance;

  bool get hasLearnedStepLength => _learnedStepLength != null;

  double get stepLength => _learnedStepLength ?? defaultStepLength;

  @override
  Map<String, String> get additionalInfo => {
    'Step length': '${stepLength.toStringAsFixed(3)} m',
    'Calibration': hasLearnedStepLength ? 'Learned' : 'Default',
    'GPS distance': '${_gpsDistance.toStringAsFixed(2)} m',
    'Step distance': '${(_totalDistance - _gpsDistance).toStringAsFixed(2)} m',
    'Step source': stepSourceId,
    'GPS fallback timeout': '${_seconds(gpsFallbackTimeout)} s',
    'Max GPS interval': '${_seconds(maxGpsInterval)} s',
    'Accepted GPS intervals': '$_acceptedGpsIntervals',
    'Rejected GPS gap': '$_rejectedGpsGap',
    'Rejected GPS coordinates': '$_rejectedGpsCoordinates',
    'Rejected GPS accuracy': '$_rejectedGpsAccuracy',
    'Rejected GPS speed': '$_rejectedGpsSpeed',
    'Calibration updates': '$_calibrationUpdates',
    'Rejected calibration': '$_rejectedCalibration',
  };

  @override
  void addSample(SensorSample sample) {
    if (sample.type == SampleType.position) {
      _addPosition(sample);
    } else if (sample.type == SampleType.steps &&
        sample.sourceId == stepSourceId) {
      _addSteps(sample);
    } else {
      return;
    }
    _calibrate();
    _updateDistance();
  }

  void _advanceTime(DateTime time) {
    if (_latestTime == null || time.isAfter(_latestTime!)) {
      _latestTime = time;
    }
  }

  void _addPosition(SensorSample sample) {
    final time = sample.timestamp;
    if (_lastGpsTime != null && !time.isAfter(_lastGpsTime!)) return;
    _lastGpsTime = time;
    _advanceTime(time);

    final latitude = sample.values[PositionKeys.latitude];
    final longitude = sample.values[PositionKeys.longitude];
    final accuracy = sample.values[PositionKeys.accuracy];
    if (latitude == null ||
        !latitude.isFinite ||
        latitude.abs() > 90 ||
        longitude == null ||
        !longitude.isFinite ||
        longitude.abs() > 180) {
      _rejectedGpsCoordinates++;
      _gpsAnchor = null;
      return;
    }
    if (accuracy == null ||
        !accuracy.isFinite ||
        accuracy < 0 ||
        accuracy > maxGpsAccuracy) {
      _rejectedGpsAccuracy++;
      _gpsAnchor = null;
      return;
    }

    final anchor = _gpsAnchor;
    if (anchor != null && time.difference(anchor.timestamp) > maxGpsInterval) {
      _rejectedGpsGap++;
    } else if (anchor != null) {
      final duration = time.difference(anchor.timestamp);
      final distance = Geolocator.distanceBetween(
        anchor.values[PositionKeys.latitude]!,
        anchor.values[PositionKeys.longitude]!,
        latitude,
        longitude,
      );
      if (distance / _seconds(duration) > maxGpsSpeed) {
        _rejectedGpsSpeed++;
        // Do not use an outlier as the next segment's starting point.
        _gpsAnchor = null;
        return;
      }
      _gpsIntervals.add((
        start: anchor.timestamp,
        end: time,
        distance: distance,
      ));
      _gpsDistance += distance;
      _acceptedGpsIntervals++;
    }
    // After an excessive gap or a rejected fix, start a new segment.
    _gpsAnchor = sample;
  }

  void _addSteps(SensorSample sample) {
    final steps = sample.values[StepKeys.cumulativeSteps];
    final time = sample.timestamp;
    if (steps == null ||
        !steps.isFinite ||
        steps < 0 ||
        steps != steps.truncateToDouble() ||
        (_lastStepTime != null && !time.isAfter(_lastStepTime!))) {
      return;
    }
    _advanceTime(time);
    final previousSteps = _lastSteps;
    final previousTime = _lastStepTime;
    // The boot counter's first reading (or a reset) is a baseline, not movement.
    if (previousSteps != null &&
        previousTime != null &&
        steps >= previousSteps) {
      _stepIntervals.add(
        _StepInterval(
          start: previousTime,
          end: time,
          steps: steps - previousSteps,
          length: stepLength,
          usedDefault: !hasLearnedStepLength,
        ),
      );
    }
    _lastSteps = steps;
    _lastStepTime = time;
  }

  void _calibrate() {
    var gpsIndex = 0;
    var stepIndex = 0;
    // Only matched time contributes to calibration. In particular, GPS before
    // the first counter reading and steps during outages cannot train a stride.
    while (gpsIndex < _gpsIntervals.length &&
        stepIndex < _stepIntervals.length) {
      final gps = _gpsIntervals[gpsIndex];
      final steps = _stepIntervals[stepIndex];
      var start = _later(gps.start, steps.start);
      final end = _earlier(gps.end, steps.end);
      if (_calibrationEnd != null) {
        start = _later(start, _calibrationEnd!);
      }
      if (end.isAfter(start)) {
        if (_calibrationEnd != start) _clearCalibrationWindow();
        final duration = end.difference(start);
        _calibrationTime += duration;
        _calibrationDistance +=
            gps.distance * _fraction(duration, gps.end.difference(gps.start));
        _calibrationSteps +=
            steps.steps *
            _fraction(duration, steps.end.difference(steps.start));
        _calibrationEnd = end;
        _learnStepLength();
      }
      if (!gps.end.isAfter(steps.end)) gpsIndex++;
      if (!steps.end.isAfter(gps.end)) stepIndex++;
    }
  }

  void _learnStepLength() {
    if (_calibrationTime < minCalibrationTime ||
        _calibrationSteps < minCalibrationSteps ||
        _calibrationDistance < minCalibrationDistance) {
      return;
    }
    final candidate = _calibrationDistance / _calibrationSteps;
    if (candidate.isFinite && candidate > 0 && candidate <= maxStepLength) {
      _calibrationUpdates++;
      final previous = _learnedStepLength;
      _learnedStepLength = previous == null
          ? candidate
          : previous + smoothingFactor * (candidate - previous);
      if (previous == null) {
        // Correct only the original default estimates, once. Later adaptations
        // apply to new steps and do not rewrite earlier personalised estimates.
        for (final interval in _stepIntervals) {
          if (interval.usedDefault) {
            interval.length = stepLength;
            interval.usedDefault = false;
          }
        }
      }
    } else {
      _rejectedCalibration++;
    }
    // Independent windows avoid repeatedly weighting the same measurements.
    _clearCalibrationWindow();
  }

  void _clearCalibrationWindow() {
    _calibrationTime = Duration.zero;
    _calibrationSteps = 0;
    _calibrationDistance = 0;
  }

  void _updateDistance() {
    var distance = _gpsDistance;
    var gpsIndex = 0;
    final anchor = _gpsAnchor;
    // While a recent good fix exists, wait for GPS to cover subsequent steps.
    // If GPS stops arriving, the next step report fills the gap retroactively.
    final pendingGpsFrom =
        anchor != null &&
            _latestTime!.difference(anchor.timestamp) <= gpsFallbackTimeout
        ? anchor.timestamp
        : null;
    for (final steps in _stepIntervals) {
      final end = pendingGpsFrom == null
          ? steps.end
          : _earlier(steps.end, pendingGpsFrom);
      if (!end.isAfter(steps.start)) continue;
      var uncovered = end.difference(steps.start).inMicroseconds;
      while (gpsIndex < _gpsIntervals.length &&
          !_gpsIntervals[gpsIndex].end.isAfter(steps.start)) {
        gpsIndex++;
      }
      for (var i = gpsIndex; i < _gpsIntervals.length; i++) {
        final gps = _gpsIntervals[i];
        if (!gps.start.isBefore(end)) break;
        final overlapStart = _later(steps.start, gps.start);
        final overlapEnd = _earlier(end, gps.end);
        if (overlapEnd.isAfter(overlapStart)) {
          uncovered -= overlapEnd.difference(overlapStart).inMicroseconds;
        }
      }
      distance +=
          steps.steps *
          steps.length *
          uncovered /
          steps.end.difference(steps.start).inMicroseconds;
    }
    _totalDistance = distance;
  }

  @override
  void reset() {
    _gpsIntervals.clear();
    _stepIntervals.clear();
    _gpsAnchor = null;
    _lastGpsTime = null;
    _lastStepTime = null;
    _latestTime = null;
    _lastSteps = null;
    _gpsDistance = 0;
    _totalDistance = 0;
    _learnedStepLength = null;
    _acceptedGpsIntervals = 0;
    _rejectedGpsGap = 0;
    _rejectedGpsCoordinates = 0;
    _rejectedGpsAccuracy = 0;
    _rejectedGpsSpeed = 0;
    _calibrationUpdates = 0;
    _rejectedCalibration = 0;
    _calibrationEnd = null;
    _clearCalibrationWindow();
  }
}

typedef _GpsInterval = ({DateTime start, DateTime end, double distance});

class _StepInterval {
  _StepInterval({
    required this.start,
    required this.end,
    required this.steps,
    required this.length,
    required this.usedDefault,
  });

  final DateTime start;
  final DateTime end;
  final double steps;
  double length;
  bool usedDefault;
}

DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
double _seconds(Duration duration) =>
    duration.inMicroseconds / Duration.microsecondsPerSecond;
double _fraction(Duration part, Duration whole) =>
    part.inMicroseconds / whole.inMicroseconds;
