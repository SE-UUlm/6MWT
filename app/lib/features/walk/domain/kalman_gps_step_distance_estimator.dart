import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../core/domain/sensor_sample.dart';
import 'calibrated_step_distance_estimator.dart';
import 'distance_estimator.dart';

/// Step odometry with a scalar Kalman estimate of distance per step.
/// GPS calibrates only straight, well-resolved windows. Covered step intervals
/// own their distance (including zero-step pauses); GPS fills only missing ones.
/// Results are provisional: learning the session's step length revises history.
class KalmanGpsStepDistanceEstimator extends DistanceEstimator {
  KalmanGpsStepDistanceEstimator({StepCalibrationConfig? config})
    : config = config ?? StepCalibrationConfig() {
    reset();
  }

  final StepCalibrationConfig config;
  late StepCalibrationHistory _history;
  final _fixes = <double, SensorSample>{};
  bool _dirty = true;
  double _distance = 0, _length = 0, _variance = 0, _gpsDistance = 0;
  int _updates = 0, _rejectedWindows = 0;

  @override
  void addSample(SensorSample sample) {
    if (!_history.add(sample)) return;
    // The shared history owns validation, source selection and time ordering.
    // Store only endpoints actually used by accepted GPS edges below; rejected
    // fixes cannot form a calibration window without continuous accepted edges.
    if (sample.type == SampleType.position &&
        sample.sourceId == _history.gpsSource) {
      _fixes[StepCalibrationHistory.time(sample)] = sample;
    }
    _dirty = true;
  }

  void _calculate() {
    if (!_dirty) return;
    _length = config.defaultLength;
    _variance = .25 * .25;
    _updates = _rejectedWindows = 0;
    double? start, end, lastUpdate;
    var path = 0.0;
    var skipEdge = false;
    for (final edge in _history.gps) {
      if (skipEdge) {
        skipEdge = false;
        continue;
      }
      if (end == null || (edge.start - end).abs() > 1e-6) {
        start = edge.start;
        path = 0;
      }
      end = edge.end;
      path += edge.amount;
      final a = start!;
      if (end - a < 10) continue;
      final first = _fixes[a]!, last = _fixes[end]!;
      final displacement = Geolocator.distanceBetween(
        first.values[PositionKeys.latitude]!,
        first.values[PositionKeys.longitude]!,
        last.values[PositionKeys.latitude]!,
        last.values[PositionKeys.longitude]!,
      );
      final positionVariance =
          math.pow(math.max(1, first.values[PositionKeys.accuracy]!), 2) +
          math.pow(math.max(1, last.values[PositionKeys.accuracy]!), 2);
      final count = StepCalibrationHistory.sum(_history.steps, a, end);
      final covered = StepCalibrationHistory.covers(_history.steps, a, end);
      // Endpoint displacement avoids accumulating positive GPS jitter. Require
      // straightness so a U-turn cannot masquerade as a shorter step length.
      final resolved =
          displacement >= math.max(10, 2 * math.sqrt(positionVariance));
      final straight = path > 0 && displacement / path >= .9;
      if (!resolved && end - a < 20 && straight) continue;
      if (covered && count >= 8 && resolved && straight) {
        final observed = displacement / count;
        final elapsed = lastUpdate == null ? 0.0 : end - lastUpdate;
        final predicted = math.min(.25 * .25, _variance + elapsed * .0001);
        // Accuracy radii are a heuristic sigma, not calibrated covariances.
        // The floor accounts for step timing and unmodelled path curvature.
        final noise = positionVariance / (count * count) + .03 * .03;
        final residual = observed - _length;
        if (observed >= .15 &&
            observed <= 1.6 &&
            residual * residual <= 9 * (predicted + noise)) {
          final gain = predicted / (predicted + noise);
          _length += gain * residual;
          _variance = (1 - gain) * predicted;
          lastUpdate = end;
          _updates++;
        } else {
          _rejectedWindows++;
        }
      } else {
        _rejectedWindows++;
      }
      // Start at the next edge, skipping its shared endpoint. This avoids
      // reusing the same GPS position noise in consecutive measurements.
      start = null;
      end = null;
      path = 0;
      skipEdge = true;
    }
    _distance = _history.steps.fold(0.0, (v, s) => v + s.amount * _length);
    _gpsDistance = 0;
    for (final edge in _history.gps) {
      var coveredSeconds = 0.0;
      for (final step in _history.steps) {
        coveredSeconds += math.max(
          0,
          math.min(edge.end, step.end) - math.max(edge.start, step.start),
        );
      }
      _gpsDistance +=
          edge.amount *
          (1 - coveredSeconds / (edge.end - edge.start)).clamp(0.0, 1.0);
    }
    _distance += _gpsDistance;
    _dirty = false;
  }

  @override
  double get totalDistance {
    _calculate();
    return _distance;
  }

  @override
  Map<String, String> get additionalInfo {
    _calculate();
    return {
      'Estimate': 'Provisional; session step length revises earlier distance',
      'Step length': '${_length.toStringAsFixed(3)} m',
      'Step length model sigma': '${math.sqrt(_variance).toStringAsFixed(3)} m',
      'Calibration windows': '$_updates',
      'Rejected calibration windows': '$_rejectedWindows',
      'Default length active': '${_updates == 0}',
      'GPS fallback distance': '${_gpsDistance.toStringAsFixed(2)} m',
      'GPS rejected': '${_history.rejectedGps}',
      'Step counter resets': '${_history.resets}',
      'GPS source': _history.gpsSource ?? 'None',
      'Step source': _history.stepSource ?? 'None',
    };
  }

  @override
  void reset() {
    _history = StepCalibrationHistory(config);
    _fixes.clear();
    _distance = _gpsDistance = 0;
    _length = config.defaultLength;
    _variance = .25 * .25;
    _updates = _rejectedWindows = 0;
    _dirty = true;
  }
}
