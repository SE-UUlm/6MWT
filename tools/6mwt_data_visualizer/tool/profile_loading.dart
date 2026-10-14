// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/features/chart/session_chart_data.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimators.dart';

void main() {
  test('profile loading and replay (diagnostic, no timing assertions)', () async {
    final snapshots = <String, Object?>{};
    final watch = Stopwatch()..start();
    final data = await SessionLoader.loadFromDataDirectory('../../data');
    print('Load all folders: ${watch.elapsedMilliseconds} ms');
    for (final group in data.sessions.where(
      (s) => s.notes.startsWith('Uni together'),
    )) {
      for (final session in group.recordings) {
        watch.reset();
        SessionChartData.fromSession(session);
        print(
          '${group.notes}/${session.deviceLabel}: ${session.samples.length} samples, chart ${watch.elapsedMicroseconds / 1000} ms',
        );
        watch.reset();
        final replay = EstimatorReplay(session);
        print('  prepare: ${watch.elapsedMicroseconds / 1000} ms');
        for (final estimator in createEstimators()) {
          watch.reset();
          final result = replay.run(estimator);
          snapshots['${group.notes}/${session.deviceLabel}/${result.name}'] = {
            'points': [
              for (final p in result.points) [p.seconds, p.meters],
            ],
            'info': result.additionalInfo,
          };
          print(
            '  ${result.name}: ${watch.elapsedMicroseconds / 1000} ms (${result.distance} m)',
          );
        }
      }
    }
    const snapshot = String.fromEnvironment('REPLAY_SNAPSHOT');
    if (snapshot.isNotEmpty) {
      await File(snapshot).writeAsString(jsonEncode(snapshots));
    }
  });
}
