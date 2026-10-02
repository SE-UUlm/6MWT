import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/calibrated_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/adaptive_gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/kalman_gps_distance_estimator.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';

import 'estimator_replay_test.dart' as fixtures;

void main() {
  for (final estimator in <DistanceEstimator>[
    CalibratedStepDistanceEstimator(),
    AdaptiveGpsStepDistanceEstimator(),
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

  test('benchmark GPS and steps with reference overlap and deterministic replay', () async {
    final root = Directory('../../data');
    expect(root.existsSync(), isTrue);
    final folders = root.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final errors = <String, List<List<double>>>{};
    // Run with --reporter expanded to reproduce the documented report.
    // ignore: avoid_print
    print(
      'Session | Raw m | Filtered m | Kalman m | Fixed steps m | Calibrated steps m | Adaptive m',
    );
    var sessions = 0;
    for (final folder in folders) {
      if (!File('${folder.path}/session.json').existsSync()) continue;
      final data = await SessionLoader.loadFromDataDirectory(folder.path);
      expect(data.sessions, hasLength(1));
      final replay = EstimatorReplay(data.sessions.single);
      final estimators = <DistanceEstimator>[
        GpsDistanceEstimator(),
        FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
        KalmanGpsDistanceEstimator(),
        StepDistanceEstimator(stepLength: .75),
        CalibratedStepDistanceEstimator(),
        AdaptiveGpsStepDistanceEstimator(),
      ];
      final results = estimators.map(replay.run).toList();
      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        expect(result.error, isNull, reason: folder.path);
        expect(result.distance, isNotNull);
        for (final point in result.points) {
          expect(point.meters.isFinite, isTrue);
          expect(point.meters, greaterThanOrEqualTo(0));
        }
        final again = replay.run(estimators[i]);
        expect(
          again.points.map((p) => p.meters),
          result.points.map((p) => p.meters),
        );
        expect(again.additionalInfo, result.additionalInfo);
      }
      final name = folder.uri.pathSegments.where((s) => s.isNotEmpty).last;
      // ignore: avoid_print
      print(
        '$name | ${results.map((r) => r.distance!.toStringAsFixed(1)).join(' | ')}'
        '',
      );
      for (final reference in replay.references) {
        final points = reference.points;
        if (points == null || points.last.meters <= 0) continue;
        final kind = reference.manual ? 'manual' : 'device';
        final delta = [
          for (final result in results)
            interpolateDistance(result.points, points.last.seconds) -
                interpolateDistance(result.points, points.first.seconds) -
                points.last.meters,
        ];
        errors.putIfAbsent(
          kind,
          () => List.generate(estimators.length, (_) => <double>[]),
        );
        for (var i = 0; i < delta.length; i++) {
          errors[kind]![i].add(delta[i].abs() / points.last.meters * 100);
        }
        // ignore: avoid_print
        print(
          '  $kind ${reference.name} (${points.last.meters.toStringAsFixed(1)} m,'
          ' ${points.first.seconds.toStringAsFixed(1)}–${points.last.seconds.toStringAsFixed(1)} s)'
          ' delta m: ${delta.map((d) => d.toStringAsFixed(1)).join(' | ')}',
        );
      }
      sessions++;
    }
    expect(sessions, greaterThan(0));
    for (final kind in errors.entries) {
      // ignore: avoid_print
      print(
        '${kind.key} mean absolute percentage error (n=${kind.value.first.length}): '
        '${kind.value.map((v) => (v.reduce((a, b) => a + b) / v.length).toStringAsFixed(2)).join(' | ')}',
      );
    }
  });
}
