import 'package:six_minute_walk_test/core/domain/sensor_sample.dart' as app;
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_mwt_visualizer/core/domain/sensor_sample.dart';
import 'package:six_mwt_visualizer/core/domain/session.dart';

final start = DateTime.utc(2026, 8, 11, 12);

SensorSample gps(
  int second,
  double longitude, {
  double accuracy = 3,
  double? distance,
}) => SensorSample(
  id: second,
  timestamp: start.add(Duration(seconds: second)),
  type: SampleType.position,
  sourceId: 'gps',
  values: {
    'latitude': 0,
    'longitude': longitude,
    'accuracy': accuracy,
    'distance': ?distance,
  },
);

SensorSample steps(int second, double count, {String source = 'pedometer'}) =>
    SensorSample(
      id: second,
      timestamp: start.add(Duration(seconds: second)),
      type: SampleType.steps,
      sourceId: source,
      values: {'cumulative_steps': count},
    );

Session session(
  List<SensorSample> samples, {
  Session? reference,
  DateTime? startedAt,
}) => Session(
  id: 'test',
  notes: '',
  startedAt: startedAt ?? start,
  duration: 360,
  distance: 123,
  phase: 'finished',
  profileId: 0,
  samples: samples,
  referenceSession: reference,
);

class RecordingEstimator extends DistanceEstimator {
  final seen = <app.SensorSample>[];
  bool resetCalled = false;
  final diagnostics = <String, String>{};
  @override
  Map<String, String> get additionalInfo => diagnostics;
  @override
  double get totalDistance => seen.length.toDouble();
  @override
  void addSample(app.SensorSample sample) {
    seen.add(sample);
    diagnostics['Samples seen'] = '${seen.length}';
  }

  @override
  void reset() {
    seen.clear();
    diagnostics.clear();
    resetCalled = true;
  }
}

class BrokenEstimator extends RecordingEstimator {
  @override
  void addSample(app.SensorSample sample) => throw StateError('broken');
}
