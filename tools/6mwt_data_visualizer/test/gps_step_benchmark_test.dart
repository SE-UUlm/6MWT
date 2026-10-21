import 'package:six_minute_walk_test/features/walk/domain/estimators/kalman_gps_step_distance_estimator.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/calibrated_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/adaptive_gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/kalman_gps_distance_estimator.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';

import '../tool/benchmark_support.dart';
import 'support/replay_fixtures.dart' as fixtures;

void main() {
  for (final estimator in <DistanceEstimator>[
    CalibratedStepDistanceEstimator(),
    AdaptiveGpsStepDistanceEstimator(),
    KalmanGpsStepDistanceEstimator(),
  ]) {
    test(
      '${estimator.runtimeType} replay matches every live update and reset',
      () {
        final replay = EstimatorReplay(
          fixtures.session([
            fixtures.gps(0, 0),
            fixtures.steps(0, 100),
            fixtures.gps(5, .00005),
            fixtures.steps(5, 110),
            fixtures.gps(10, .0001),
            fixtures.steps(10, 120),
            fixtures.steps(15, 130),
            fixtures.steps(20, 140),
            fixtures.gps(30, .0003),
            fixtures.steps(30, 160),
            fixtures.gps(35, .0004),
            fixtures.steps(35, 170),
            fixtures.gps(40, .0005),
            fixtures.steps(40, 180),
          ]),
        );
        final live = <double, double>{};
        for (final sample in replay.samples) {
          estimator.addSample(sample);
          live[sample.timestamp.difference(replay.start).inMicroseconds / 1e6] =
              estimator.totalDistance;
        }
        final info = estimator.additionalInfo;
        final result = replay.run(estimator);
        expect(result.error, isNull);
        expect(result.points.map((p) => p.meters), live.values);
        expect(result.additionalInfo, info);
        expect(replay.run(estimator).points.map((p) => p.meters), live.values);
      },
    );
  }

  test('benchmark every recording with shared reference comparisons', () async {
    final recordings = await loadBenchmarkRecordings('../../data');
    expect(recordings, isNotEmpty);
    final comparisons = <Map<String, Object?>>[];
    for (final recording in recordings) {
      final replay = EstimatorReplay(recording);
      final estimators = <DistanceEstimator>[
        createProductionEstimator(),
        GpsDistanceEstimator(),
        FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
        KalmanGpsDistanceEstimator(),
        StepDistanceEstimator(stepLength: .75),
        CalibratedStepDistanceEstimator(),
        AdaptiveGpsStepDistanceEstimator(),
        KalmanGpsStepDistanceEstimator(),
      ];
      for (final estimator in estimators) {
        final result = replay.run(estimator);
        expect(result.error, isNull, reason: recording.recordingLabel);
        expect(result.distance, isNotNull, reason: recording.recordingLabel);

        for (final point in result.points) {
          expect(point.meters.isFinite, isTrue);
          expect(point.meters, greaterThanOrEqualTo(0));
        }
        final again = replay.run(estimator);
        expect(
          again.points.map((p) => p.meters),
          result.points.map((p) => p.meters),
        );
        expect(again.additionalInfo, result.additionalInfo);
        // ignore: avoid_print
        print(
          '${recording.recordingLabel} | ${result.name} | '
          'total ${benchmarkNumber(result.distance)} m | ${result.additionalInfo}',
        );
        final rows = compareReferences(recording, replay, result);
        comparisons.addAll(rows);
        for (final row in rows) {
          // ignore: avoid_print
          print(comparisonLine(row));
        }
      }
    }
    for (final line in summaryLines(comparisons)) {
      // ignore: avoid_print
      print(line);
    }
  });
}
