import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import '../../../core/domain/sensor_sample.dart';
import 'distance_estimator.dart';

/// Experimental defaults; bounds may underestimate very short clinical steps.
class StepCalibrationConfig {
  StepCalibrationConfig({
    this.defaultLength = 0.75,
    this.maxAccuracy = 10,
    this.maxSpeed = 4,
    this.maxGpsInterval = 10,
    this.localSeconds = 60,
  }) {
    if ([
      defaultLength,
      maxAccuracy,
      maxSpeed,
      maxGpsInterval,
      localSeconds,
    ].any((v) => !v.isFinite || v <= 0)) {
      throw ArgumentError('Calibration parameters must be finite and positive');
    }
  }
  final double defaultLength,
      maxAccuracy,
      maxSpeed,
      maxGpsInterval,
      localSeconds;
}

/// A measured increment distributed uniformly between two sensor timestamps.
class CalibrationSegment {
  const CalibrationSegment(this.start, this.end, this.amount);
  final double start, end, amount;
  double between(double a, double b) =>
      amount *
      math.max(0, math.min(b, end) - math.max(a, start)) /
      (end - start);
}

class StepCalibrationWindow {
  const StepCalibrationWindow(this.start, this.end, this.length);
  final double start, end, length;
}

/// Shared sensor-time history. References and wall-clock time never enter it.
/// Histories are small (one six-minute walk); calculations are cached per event.
class StepCalibrationHistory {
  StepCalibrationHistory(this.config);
  final StepCalibrationConfig config;
  final gps = <CalibrationSegment>[];
  final steps = <CalibrationSegment>[];
  String? gpsSource, stepSource;
  double? _gpsSeen, _stepSeen, _count;
  SensorSample? _fix;
  double? start, end;
  int rejectedGps = 0, resets = 0;

  static double time(SensorSample s) =>
      s.timestamp.microsecondsSinceEpoch / 1e6;

  bool add(SensorSample s) {
    if (s.type != SampleType.position && s.type != SampleType.steps) {
      return false;
    }
    final t = time(s);
    if (s.type == SampleType.steps) {
      final count = s.values[StepKeys.cumulativeSteps];
      if (count == null ||
          !count.isFinite ||
          count < 0 ||
          (stepSource != null && s.sourceId != stepSource) ||
          (_stepSeen != null && t <= _stepSeen!)) {
        return false;
      }
      stepSource ??= s.sourceId;
      if (_count != null) {
        if (count >= _count!) {
          steps.add(CalibrationSegment(_stepSeen!, t, count - _count!));
        } else {
          resets++;
        }
      }
      _count = count;
      _stepSeen = t;
    } else {
      if ((gpsSource != null && s.sourceId != gpsSource) ||
          (_gpsSeen != null && t <= _gpsSeen!)) {
        return false;
      }
      final lat = s.values[PositionKeys.latitude];
      final lon = s.values[PositionKeys.longitude];
      final acc = s.values[PositionKeys.accuracy];
      final valid =
          lat != null &&
          lon != null &&
          acc != null &&
          lat.isFinite &&
          lon.isFinite &&
          acc.isFinite &&
          lat.abs() <= 90 &&
          lon.abs() <= 180 &&
          acc > 0 &&
          acc <= config.maxAccuracy;
      if (!valid) {
        rejectedGps++;
        _fix = null;
        if (gpsSource == null) return false;
        _gpsSeen = t;
      } else {
        gpsSource ??= s.sourceId;
        final previous = _fix;
        if (previous != null) {
          final dt = t - time(previous);
          final meters = Geolocator.distanceBetween(
            previous.values[PositionKeys.latitude]!,
            previous.values[PositionKeys.longitude]!,
            lat,
            lon,
          );
          if (dt <= config.maxGpsInterval && meters / dt <= config.maxSpeed) {
            gps.add(CalibrationSegment(time(previous), t, meters));
          } else {
            rejectedGps++;
          }
        }
        // A new candidate needs another plausible fix before contributing meters.
        _fix = s;
        _gpsSeen = t;
      }
    }
    start = math.min(start ?? t, t);
    end = math.max(end ?? t, t);
    return true;
  }

  static double sum(List<CalibrationSegment> segments, double a, double b) =>
      segments.fold(0.0, (v, s) => v + s.between(a, b));

  static bool covers(List<CalibrationSegment> segments, double a, double b) {
    var cursor = a;
    for (final s in segments) {
      if (s.end <= cursor) continue;
      if (s.start > cursor + 1e-6) return false;
      cursor = s.end;
      if (cursor >= b - 1e-6) return true;
    }
    return false;
  }

  List<StepCalibrationWindow> windows() {
    if (gps.isEmpty || steps.isEmpty) return [];
    final result = <StepCalibrationWindow>[];
    final first = math.max(gps.first.start, steps.first.start);
    final last = math.min(gps.last.end, steps.last.end);
    for (var a = first; a + 10 <= last + 1e-6; a += 5) {
      final b = a + 10;
      if (!covers(gps, a, b) || !covers(steps, a, b)) continue;
      final d = sum(gps, a, b), n = sum(steps, a, b);
      if (d < 5 || n < 6) continue;
      final length = d / n;
      if (length >= 0.25 && length <= 2) {
        result.add(StepCalibrationWindow(a, b, length));
      }
    }
    return result;
  }

  static double median(Iterable<double> values) {
    final sorted = values.toList()..sort();
    return sorted[sorted.length ~/ 2].clamp(0.35, 1.35);
  }
}

/// All observed steps use the current session median, including earlier steps.
class CalibratedStepDistanceEstimator extends DistanceEstimator {
  CalibratedStepDistanceEstimator({StepCalibrationConfig? config})
    : config = config ?? StepCalibrationConfig() {
    reset();
  }
  final StepCalibrationConfig config;
  late StepCalibrationHistory _history;
  bool _dirty = true;
  double _distance = 0, _length = 0;
  int _windows = 0;

  void _calculate() {
    if (!_dirty) return;
    final windows = _history.windows();
    _windows = windows.length;
    _length = windows.isEmpty
        ? config.defaultLength
        : StepCalibrationHistory.median(windows.map((w) => w.length));
    _distance = _history.steps.fold(0.0, (v, s) => v + s.amount) * _length;
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
      'Estimate': 'Provisional; calibration can revise earlier distance',
      'Step length': '${_length.toStringAsFixed(3)} m',
      'Calibration windows': '$_windows',
      'Default length active': '${_windows == 0}',
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
    _distance = 0;
    _length = config.defaultLength;
    _windows = 0;
  }
}
