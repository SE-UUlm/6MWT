import 'dart:math' as math;

import '../../../core/domain/sensor_sample.dart';
import 'calibrated_step_distance_estimator.dart';
import 'distance_estimator.dart';

/// GPS on covered intervals, locally calibrated steps on their complement.
/// Retains the short session history so later calibration can revise GPS gaps.
class AdaptiveGpsStepDistanceEstimator extends DistanceEstimator {
  AdaptiveGpsStepDistanceEstimator({StepCalibrationConfig? config})
    : config = config ?? StepCalibrationConfig() {
    reset();
  }
  final StepCalibrationConfig config;
  late StepCalibrationHistory _history;
  bool _dirty = true;
  double _distance = 0, _gpsMeters = 0, _stepMeters = 0;
  double _defaultMeters = 0, _uncovered = 0, _correction = 0;
  double _currentLength = 0;
  int _windowCount = 0, _gapCount = 0, _pending = 0;

  void _calculate() {
    if (!_dirty) return;
    _gpsMeters = _history.gps.fold(0.0, (v, s) => v + s.amount);
    _stepMeters = _defaultMeters = _uncovered = _correction = 0;
    _gapCount = _pending = 0;
    final windows = _history.windows();
    _windowCount = windows.length;
    final start = _history.start, end = _history.end;
    _currentLength = config.defaultLength;
    if (start != null && end != null) {
      final recent = windows.where((w) => w.start >= end - config.localSeconds);
      if (recent.isNotEmpty) {
        _currentLength = StepCalibrationHistory.median(
          recent.map((w) => w.length),
        );
      }
      // Merge adjacent GPS edges; every remaining interval is exclusively steps.
      final runs = <CalibrationSegment>[];
      for (final s in _history.gps) {
        if (runs.isNotEmpty && (runs.last.end - s.start).abs() < 1e-6) {
          final previous = runs.removeLast();
          runs.add(CalibrationSegment(previous.start, s.end, 0));
        } else {
          runs.add(CalibrationSegment(s.start, s.end, 0));
        }
      }
      var cursor = start;
      for (var i = 0; i <= runs.length; i++) {
        final right = i < runs.length ? runs[i] : null;
        final left = i > 0 ? runs[i - 1] : null;
        final gapEnd = right?.start ?? end;
        if (gapEnd > cursor) {
          _gap(cursor, gapEnd, left, right, windows, end, i == runs.length - 1);
        }
        if (right != null) cursor = right.end;
      }
    }
    _distance = _gpsMeters + _stepMeters;
    _dirty = false;
  }

  void _gap(
    double a,
    double b,
    CalibrationSegment? left,
    CalibrationSegment? right,
    List<StepCalibrationWindow> windows,
    double now,
    bool lastRun,
  ) {
    _gapCount++;
    // Only the immediately adjacent good run may calibrate this gap.
    final before = windows.where(
      (w) =>
          left != null &&
          w.start >= math.max(left.start, a - config.localSeconds) &&
          w.end <= a,
    );
    final after = windows.where(
      (w) =>
          right != null &&
          w.start >= b &&
          w.end <= math.min(right.end, b + config.localSeconds),
    );
    final prior = before.isEmpty
        ? null
        : StepCalibrationHistory.median(before.map((w) => w.length));
    final following = after.isEmpty
        ? null
        : StepCalibrationHistory.median(after.map((w) => w.length));
    final from = prior ?? following ?? config.defaultLength;
    final to = following ?? prior ?? config.defaultLength;
    final defaultUsed = prior == null && following == null;
    if (right == null || (now < b + config.localSeconds && lastRun)) {
      _pending++;
    }
    var covered = 0.0;
    for (final s in _history.steps) {
      final x = math.max(a, s.start), y = math.min(b, s.end);
      if (y <= x) continue;
      covered += y - x;
      // Exact integral of a linear length over a constant-rate step segment.
      final fraction = ((x + y) / 2 - a) / (b - a);
      final length = from + (to - from) * fraction;
      final count = s.between(x, y);
      final meters = count * length;
      _stepMeters += meters;
      if (defaultUsed) _defaultMeters += meters;
      _correction += meters - count * (prior ?? config.defaultLength);
    }
    _uncovered += math.max(0, b - a - covered);
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
      'Estimate': 'Provisional; gaps may be revised up or down',
      'Recent step length': '${_currentLength.toStringAsFixed(3)} m',
      'Calibration windows': '$_windowCount',
      'GPS distance': '${_gpsMeters.toStringAsFixed(2)} m',
      'Step distance': '${_stepMeters.toStringAsFixed(2)} m',
      'Default-length distance': '${_defaultMeters.toStringAsFixed(2)} m',
      'GPS gaps': '$_gapCount',
      'Gaps awaiting GPS/calibration': '$_pending',
      'Uncovered duration': '${_uncovered.toStringAsFixed(1)} s',
      'Correction from following calibration':
          '${_correction.toStringAsFixed(2)} m',
      'GPS rejected': '${_history.rejectedGps}',
      'Step counter resets': '${_history.resets}',
      'GPS source': _history.gpsSource ?? 'None',
      'Step source': _history.stepSource ?? 'None',
    };
  }

  @override
  void addSample(SensorSample sample) {
    if (_history.add(sample)) _dirty = true;
  }

  @override
  void reset() {
    _history = StepCalibrationHistory(config);
    _dirty = true;
    _distance = _gpsMeters = _stepMeters = _defaultMeters = _uncovered =
        _correction = 0;
    _currentLength = config.defaultLength;
    _windowCount = _gapCount = _pending = 0;
  }
}
