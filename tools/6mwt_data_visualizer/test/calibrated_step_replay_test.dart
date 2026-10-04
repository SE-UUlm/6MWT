import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/calibrated_step_distance_estimator.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';
import 'estimator_replay_test.dart' as fixtures;

void main() {
  test('calibrated steps match live processing and reset replay', () {
    final replay = EstimatorReplay(
      fixtures.session([
        fixtures.gps(0, 0),
        fixtures.steps(0, 100),
        fixtures.gps(5, .00005),
        fixtures.steps(5, 110),
        fixtures.gps(10, .0001),
        fixtures.steps(10, 120),
        fixtures.steps(15, 130),
      ]),
    );
    final e = CalibratedStepDistanceEstimator();
    for (final s in replay.samples) {
      e.addSample(s);
    }
    final distance = e.totalDistance, info = e.additionalInfo;
    final result = replay.run(e);
    expect(result.error, isNull);
    expect(result.distance, distance);
    expect(result.additionalInfo, info);
    expect(
      replay.run(e).points.map((p) => p.meters),
      result.points.map((p) => p.meters),
    );
  });
}
