import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/kalman_gps_distance_estimator.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';

import '../tool/benchmark_support.dart';
import 'estimator_replay_test.dart' as fixtures;

void main() {
  test('Kalman replay matches direct streaming and resets all state', () {
    final replay = EstimatorReplay(
      fixtures.session([
        fixtures.gps(0, 0),
        fixtures.gps(5, 0.00007),
        fixtures.steps(6, 100),
        fixtures.gps(7, 1),
        fixtures.gps(10, 0.00014),
        fixtures.gps(30, 0.0004),
        fixtures.gps(35, 0.00047),
      ]),
    );
    final estimator = KalmanGpsDistanceEstimator();
    for (final sample in replay.samples) {
      estimator.addSample(sample);
    }
    final streamedDistance = estimator.totalDistance;
    final streamedInfo = estimator.additionalInfo;
    final result = replay.run(estimator);
    expect(result.error, isNull);
    expect(result.distance, streamedDistance);
    expect(result.additionalInfo, streamedInfo);
    expect(replay.run(estimator).distance, result.distance);
  });

  test('benchmark every recording with shared reference comparisons', () async {
    final recordings = await loadBenchmarkRecordings('../../data');
    expect(recordings, isNotEmpty);
    final comparisons = <Map<String, Object?>>[];
    for (final recording in recordings) {
      final replay = EstimatorReplay(recording);
      final estimators = <DistanceEstimator>[
        GpsDistanceEstimator(),
        FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
        KalmanGpsDistanceEstimator(),
      ];
      for (final estimator in estimators) {
        final result = replay.run(estimator);
        expect(result.error, isNull, reason: recording.recordingLabel);
        expect(result.distance, isNotNull, reason: recording.recordingLabel);
        var previous = 0.0;
        for (final point in result.points) {
          expect(point.meters.isFinite, isTrue);
          expect(point.meters, greaterThanOrEqualTo(previous));
          previous = point.meters;
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
