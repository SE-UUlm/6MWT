import '../../../../core/domain/sensor_sample.dart';
import 'distance_confidence.dart';
import 'distance_estimator.dart';
import 'step_calibration_history.dart';

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
  List<double> _strides = const [];

  void _calculate() {
    if (!_dirty) return;
    final windows = _history.windows();
    _windows = windows.length;
    _strides = [for (final w in windows) w.length];
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

  /// All distance comes from steps; GPS only calibrates the stride.
  @override
  DistanceConfidence get confidence {
    _calculate();
    return ConfidenceHeuristics.combine(
      total: _distance,
      gpsDistance: 0,
      gpsQuality: 0,
      otherQuality: ConfidenceHeuristics.strideQuality(_strides),
    );
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
    _strides = const [];
  }
}
