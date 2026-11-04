import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

import 'default_step_length.dart';
import 'distance_confidence.dart';
import 'distance_estimator.dart';
import 'gps_step_distance_estimator.dart';

/// [GpsStepDistanceEstimator]'s GPS segments, step fallback and session stride,
/// with two physical plausibility bounds between GPS and steps:
///
/// * **Step cap.** Within a short window around each GPS segment, GPS may not
///   exceed the counted steps × learned stride × [capStrideFactor] (plus a
///   small allowance), but is never capped below the window's straight-line
///   displacement. This removes jitter while standing or with dense noisy fixes,
///   yet keeps the distance when the step counter freezes while walking. The
///   cap is relative to the learned stride, so a counter that consistently
///   under- or overcounts is absorbed by the calibration.
/// * **Bridge.** Across a gap of up to [bridgeMaxSeconds] between two good
///   fixes, the walked path is at least the straight line minus the fixes'
///   uncertainty. If the steps during the gap account for less, the difference
///   is added. This recovers catch-up jumps of lagging GPS and step counters
///   that undercount without a learned stride.
///
/// Fixes with excessive accuracy radius are skipped without dropping the last
/// good fix, so that a bridge can span them.
///
/// Experimental. Like the main estimator, results are provisional: the first
/// learned stride corrects earlier step distance, and caps and bridges are
/// revised while step data for their window arrives, so the total can decrease.
class FusedGpsStepDistanceEstimator extends DistanceEstimator {
  FusedGpsStepDistanceEstimator({
    super.name,
    required this.stepSourceId,
    this.capStrideFactor = 1.15,
    this.capWindowSeconds = 5,
    this.capAllowance = 0.1,
    this.bridgeMaxSeconds = 60,
    this.bridgeAccuracyFactor = 0.5,
  }) {
    if (!(capStrideFactor > 0) ||
        !(capWindowSeconds > 0) ||
        !(capAllowance >= 0) ||
        !(bridgeMaxSeconds >= 0) ||
        !(bridgeAccuracyFactor >= 0)) {
      throw ArgumentError('Fusion parameters must be finite and nonnegative.');
    }
  }

  @override
  String get defaultName => 'Fused GPS + steps';

  final String stepSourceId;

  /// GPS may exceed steps × learned stride by at most this factor.
  final double capStrideFactor;

  /// Window centred on each GPS segment that the cap compares.
  final double capWindowSeconds;

  /// Additional GPS allowance in m/s within the cap window.
  final double capAllowance;

  /// Longest gap between two good fixes that is bridged. 0 disables bridges.
  final double bridgeMaxSeconds;

  /// The bridge chord is reduced by this × the sum of both fixes' accuracy.
  final double bridgeAccuracyFactor;

  // Shared with the main estimator.
  static const maxGpsAccuracy = 10.0;
  static const maxGpsSpeed = 3.5;
  static const maxGpsInterval = 5.0;
  static const gpsFallbackTimeout = 5.0;
  static const maxStepLength = 1.5;
  static const minCalibrationTime = 15.0;
  static const minCalibrationSteps = 10.0;
  static const minCalibrationDistance = 10.0;
  static const smoothingFactor = 0.2;

  final _gps = <_GpsSegment>[];
  final _bridges = <_GpsSegment>[];
  final _steps = <_StepInterval>[];
  SensorSample? _anchor;
  double? _lastGpsTime, _lastStepTime, _latestTime, _lastSteps;
  double? _learnedStepLength;
  double _initialStepLength = GpsStepDistanceEstimator.defaultStepLength;

  double _totalDistance = 0;
  double _gpsDistance = 0;
  double _cappedMeters = 0;
  double _bridgeMeters = 0;
  double _gpsAccuracySum = 0;
  int _rejectedGpsCoordinates = 0;
  int _rejectedGpsAccuracy = 0;
  int _rejectedGpsSpeed = 0;
  int _rejectedGpsGap = 0;
  int _rejectedCalibration = 0;
  final _strideCandidates = <double>[];

  int _calibrationGps = 0, _calibrationStep = 0;
  double? _calibrationEnd;
  double _calibrationTime = 0, _calibrationSteps = 0, _calibrationDistance = 0;

  @override
  double get totalDistance => _totalDistance;

  bool get hasLearnedStepLength => _learnedStepLength != null;

  double get stepLength => _learnedStepLength ?? _initialStepLength;

  @override
  void configureProfile({num? heightCm, String? gender}) {
    _initialStepLength = estimateDefaultStepLength(
      heightCm: heightCm,
      gender: gender,
    );
  }

  @override
  Map<String, String> get additionalInfo => {
    'Estimate': 'Provisional; caps and bridges may be revised; fuseduu6mwt',
    'version': 'UULM-6MWT-FGSDE-v1',
    'Step length': '${stepLength.toStringAsFixed(3)} m',
    'Calibration': hasLearnedStepLength ? 'Learned' : 'Default',
    'GPS distance': '${_gpsDistance.toStringAsFixed(2)} m',
    'Removed by step cap': '${_cappedMeters.toStringAsFixed(2)} m',
    'Added by bridges': '${_bridgeMeters.toStringAsFixed(2)} m',
    'Step distance':
        '${(_totalDistance - _gpsDistance - _bridgeMeters).toStringAsFixed(2)} m',
    'Bridges': '${_bridges.length}',
    'Accepted GPS intervals': '${_gps.length}',
    'Rejected GPS coordinates': '$_rejectedGpsCoordinates',
    'Rejected GPS accuracy': '$_rejectedGpsAccuracy',
    'Rejected GPS speed': '$_rejectedGpsSpeed',
    'Rejected GPS gap': '$_rejectedGpsGap',
    'Calibration updates': '${_strideCandidates.length}',
    'Rejected calibration': '$_rejectedCalibration',
    'Step source': stepSourceId,
  };

  /// GPS quality for the (capped) GPS share, stride consistency for the rest.
  @override
  DistanceConfidence get confidence => ConfidenceHeuristics.combine(
    total: _totalDistance,
    gpsDistance: _gpsDistance,
    gpsQuality: ConfidenceHeuristics.gpsQuality(
      accuracySum: _gpsAccuracySum,
      accepted: _gps.length,
      rejected:
          _rejectedGpsCoordinates + _rejectedGpsAccuracy + _rejectedGpsSpeed,
    ),
    otherQuality: ConfidenceHeuristics.strideQuality(
      _strideCandidates,
      rejected: _rejectedCalibration,
    ),
  );

  static double _time(SensorSample s) =>
      s.timestamp.microsecondsSinceEpoch / Duration.microsecondsPerSecond;

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

  void _advanceTime(double time) {
    if (_latestTime == null || time > _latestTime!) _latestTime = time;
  }

  void _addPosition(SensorSample sample) {
    final time = _time(sample);
    if (_lastGpsTime != null && time <= _lastGpsTime!) return;
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
      _anchor = null;
      return;
    }
    if (accuracy == null ||
        !accuracy.isFinite ||
        accuracy < 0 ||
        accuracy > maxGpsAccuracy) {
      // Skip only this fix; a later good fix may bridge to the anchor.
      _rejectedGpsAccuracy++;
      return;
    }
    final anchor = _anchor;
    if (anchor == null) {
      _anchor = sample;
      return;
    }
    final duration = time - _time(anchor);
    final distance = _distance(anchor, sample);
    if (duration > maxGpsInterval) {
      _rejectedGpsGap++;
      if (duration <= bridgeMaxSeconds && distance / duration <= maxGpsSpeed) {
        _bridges.add(_GpsSegment(anchor, sample, distance));
      }
      _anchor = sample;
      return;
    }
    if (distance / duration > maxGpsSpeed) {
      // Skip the outlier and keep the last good fix as the anchor.
      _rejectedGpsSpeed++;
      return;
    }
    _gps.add(_GpsSegment(anchor, sample, distance));
    _gpsAccuracySum += accuracy;
    _anchor = sample;
  }

  void _addSteps(SensorSample sample) {
    final steps = sample.values[StepKeys.cumulativeSteps];
    final time = _time(sample);
    if (steps == null ||
        !steps.isFinite ||
        steps < 0 ||
        steps != steps.truncateToDouble() ||
        (_lastStepTime != null && time <= _lastStepTime!)) {
      return;
    }
    _advanceTime(time);
    // The boot counter's first reading (or a reset) is a baseline.
    if (_lastSteps != null && _lastStepTime != null && steps >= _lastSteps!) {
      _steps.add(
        _StepInterval(
          _lastStepTime!,
          time,
          steps - _lastSteps!,
          stepLength,
          !hasLearnedStepLength,
        ),
      );
    }
    _lastSteps = steps;
    _lastStepTime = time;
  }

  /// Same matched-time calibration as the main estimator.
  void _calibrate() {
    var gpsIndex = _calibrationGps, stepIndex = _calibrationStep;
    while (gpsIndex < _gps.length && stepIndex < _steps.length) {
      final gps = _gps[gpsIndex], steps = _steps[stepIndex];
      var start = math.max(gps.start, steps.start);
      final end = math.min(gps.end, steps.end);
      if (_calibrationEnd != null) start = math.max(start, _calibrationEnd!);
      if (end > start) {
        if (_calibrationEnd != start) _clearCalibrationWindow();
        final duration = end - start;
        _calibrationTime += duration;
        _calibrationDistance += gps.distance * duration / gps.duration;
        _calibrationSteps += steps.steps * duration / steps.duration;
        _calibrationEnd = end;
        _learnStepLength();
      }
      if (gps.end <= steps.end) gpsIndex++;
      if (steps.end <= gps.end) stepIndex++;
    }
    // The last pair may still overlap intervals that arrive later.
    _calibrationGps = math.max(0, gpsIndex - 1);
    _calibrationStep = math.max(0, stepIndex - 1);
  }

  void _learnStepLength() {
    if (_calibrationTime < minCalibrationTime ||
        _calibrationSteps < minCalibrationSteps ||
        _calibrationDistance < minCalibrationDistance) {
      return;
    }
    final candidate = _calibrationDistance / _calibrationSteps;
    if (candidate.isFinite && candidate > 0 && candidate <= maxStepLength) {
      _strideCandidates.add(candidate);
      final previous = _learnedStepLength;
      _learnedStepLength = previous == null
          ? candidate
          : previous + smoothingFactor * (candidate - previous);
      if (previous == null) {
        for (final interval in _steps) {
          if (interval.usedDefault) {
            interval.length = stepLength;
            interval.usedDefault = false;
          }
        }
      }
    } else {
      _rejectedCalibration++;
    }
    _clearCalibrationWindow();
  }

  void _clearCalibrationWindow() {
    _calibrationTime = 0;
    _calibrationSteps = 0;
    _calibrationDistance = 0;
  }

  /// Sum of [value] over [segments] overlapping [a, b], pro rata by time.
  static double _between<T extends _Interval>(
    List<T> segments,
    double a,
    double b,
    double Function(T) value,
  ) {
    var total = 0.0;
    for (final s in segments) {
      if (s.end <= a) continue;
      if (s.start >= b) break;
      total +=
          value(s) * (math.min(b, s.end) - math.max(a, s.start)) / s.duration;
    }
    return total;
  }

  double _cappedDistance(_GpsSegment segment) {
    final learned = _learnedStepLength;
    if (learned == null) return segment.distance;
    final cached = segment.capped;
    if (cached != null) return cached;
    final middle = (segment.start + segment.end) / 2;
    final a = middle - capWindowSeconds / 2, b = middle + capWindowSeconds / 2;
    // Without full step coverage (e.g. no counter) GPS stays unbounded.
    if (_steps.isEmpty || _steps.first.start > a || _steps.last.end < b) {
      return segment.distance;
    }
    final gps = _between(_gps, a, b, (s) => s.distance);
    var allowed =
        _between(_steps, a, b, (s) => s.steps) * learned * capStrideFactor +
        capAllowance * capWindowSeconds;
    if (gps > allowed) {
      // Never below the straight-line displacement across the window, so a
      // frozen counter cannot erase real movement.
      _GpsSegment? first, last;
      for (final s in _gps) {
        if (s.end <= a) continue;
        if (s.start >= b) break;
        first ??= s;
        last = s;
      }
      final span = math.max(capWindowSeconds, last!.end - first!.start);
      allowed = math.max(
        allowed,
        _distance(first.from, last.to) * capWindowSeconds / span,
      );
    }
    final value = gps <= allowed
        ? segment.distance
        : segment.distance * allowed / gps;
    // Final once no later GPS can fall into the window.
    if (_lastGpsTime! >= b) segment.capped = value;
    return value;
  }

  void _updateDistance() {
    var gpsDistance = 0.0, raw = 0.0;
    for (final segment in _gps) {
      raw += segment.distance;
      gpsDistance += _cappedDistance(segment);
    }
    _gpsDistance = gpsDistance;
    _cappedMeters = raw - gpsDistance;

    var distance = gpsDistance;
    final anchor = _anchor;
    // Wait for GPS after a recent good fix before counting uncovered steps.
    final pendingFrom =
        anchor != null && _latestTime! - _time(anchor) <= gpsFallbackTimeout
        ? _time(anchor)
        : null;
    var gpsIndex = 0;
    for (final steps in _steps) {
      final end = pendingFrom == null
          ? steps.end
          : math.min(steps.end, pendingFrom);
      if (end <= steps.start) continue;
      var uncovered = end - steps.start;
      while (gpsIndex < _gps.length && _gps[gpsIndex].end <= steps.start) {
        gpsIndex++;
      }
      for (var i = gpsIndex; i < _gps.length; i++) {
        final gps = _gps[i];
        if (gps.start >= end) break;
        final overlap =
            math.min(end, gps.end) - math.max(steps.start, gps.start);
        if (overlap > 0) uncovered -= overlap;
      }
      distance += steps.steps * steps.length * uncovered / steps.duration;
    }

    // A straight line between two good fixes is a lower bound of the path.
    var bridgeMeters = 0.0;
    for (final bridge in _bridges) {
      final lower =
          bridge.distance -
          bridgeAccuracyFactor *
              (bridge.from.values[PositionKeys.accuracy]! +
                  bridge.to.values[PositionKeys.accuracy]!);
      final steps = _between(
        _steps,
        bridge.start,
        bridge.end,
        (s) => s.steps * s.length,
      );
      if (lower > steps) bridgeMeters += lower - steps;
    }
    _bridgeMeters = bridgeMeters;
    _totalDistance = distance + bridgeMeters;
  }

  static double _distance(SensorSample a, SensorSample b) =>
      Geolocator.distanceBetween(
        a.values[PositionKeys.latitude]!,
        a.values[PositionKeys.longitude]!,
        b.values[PositionKeys.latitude]!,
        b.values[PositionKeys.longitude]!,
      );

  @override
  void reset() {
    _gps.clear();
    _bridges.clear();
    _steps.clear();
    _anchor = null;
    _lastGpsTime = _lastStepTime = _latestTime = _lastSteps = null;
    _learnedStepLength = null;
    _totalDistance = _gpsDistance = _cappedMeters = _bridgeMeters = 0;
    _gpsAccuracySum = 0;
    _rejectedGpsCoordinates = _rejectedGpsAccuracy = _rejectedGpsSpeed = 0;
    _rejectedGpsGap = _rejectedCalibration = 0;
    _strideCandidates.clear();
    _calibrationGps = _calibrationStep = 0;
    _calibrationEnd = null;
    _clearCalibrationWindow();
  }
}

abstract class _Interval {
  double get start;
  double get end;
  double get duration => end - start;
}

class _GpsSegment extends _Interval {
  _GpsSegment(this.from, this.to, this.distance)
    : start = FusedGpsStepDistanceEstimator._time(from),
      end = FusedGpsStepDistanceEstimator._time(to);
  final SensorSample from, to;
  @override
  final double start, end;
  final double distance;

  /// Cap result once its window is complete.
  double? capped;
}

class _StepInterval extends _Interval {
  _StepInterval(
    this.start,
    this.end,
    this.steps,
    this.length,
    this.usedDefault,
  );
  @override
  final double start, end;
  final double steps;
  double length;
  bool usedDefault;
}
