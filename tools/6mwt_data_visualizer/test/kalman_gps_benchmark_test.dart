import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/kalman_gps_distance_estimator.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';

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

  test('benchmark recorded GPS with reference overlap and deterministic replay', () async {
    final root = Directory('../../data');
    expect(root.existsSync(), isTrue);
    final folders = root.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final errors = <String, List<List<double>>>{};
    // Run with --reporter expanded to reproduce the documented report.
    // ignore: avoid_print
    print('Session | Raw m | Simple m | Kalman m | Gaps | Gap m');
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
      ];
      final results = estimators.map(replay.run).toList();
      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        expect(result.error, isNull, reason: folder.path);
        expect(result.distance, isNotNull);
        var previous = 0.0;
        for (final point in result.points) {
          expect(point.meters.isFinite, isTrue);
          expect(point.meters, greaterThanOrEqualTo(previous));
          previous = point.meters;
        }
        final again = replay.run(estimators[i]);
        expect(
          again.points.map((p) => p.meters),
          result.points.map((p) => p.meters),
        );
        expect(again.additionalInfo, result.additionalInfo);
      }
      final name = folder.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final info = results.last.additionalInfo;
      // ignore: avoid_print
      print(
        '$name | ${results.map((r) => r.distance!.toStringAsFixed(1)).join(' | ')}'
        ' | ${info['GPS gaps']} | ${info['Gap distance (straight-line estimate)']}',
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
        errors.putIfAbsent(kind, () => [[], [], []]);
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
