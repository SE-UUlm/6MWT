// Run from the visualizer directory:
// flutter test tool/compare_gps_gaps.dart --reporter expanded
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/gps_step_distance_estimator.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimators.dart';

void main() {
  test('compare GPS interval variants over every repository recording', () async {
    final data = await SessionLoader.loadFromDataDirectory('../../data');
    expect(data.sessions, isNotEmpty);
    final sessions = data.sessions.toList()
      ..sort((a, b) => a.notes.compareTo(b.notes));
    final runs = <Map<String, Object?>>[];
    final comparisons = <Map<String, Object?>>[];
    for (final session in sessions) {
      final replay = EstimatorReplay(session);
      for (final estimator
          in createEstimators().whereType<GpsStepDistanceEstimator>()) {
        final result = replay.run(estimator);
        expect(result.error, isNull, reason: session.notes);
        expect(result.distance?.isFinite, isTrue, reason: session.notes);
        runs.add({
          'recording': session.notes,
          'maxGpsIntervalSeconds': estimator.maxGpsInterval.inSeconds,
          'distanceMeters': result.distance,
          'learned': estimator.hasLearnedStepLength,
          'stepLengthMeters': estimator.stepLength,
          'diagnostics': result.additionalInfo,
        });
        for (final reference in replay.references) {
          final points = reference.points;
          if (points == null) continue;
          final measured =
              interpolateDistance(result.points, points.last.seconds) -
              interpolateDistance(result.points, points.first.seconds);
          final expected = points.last.meters;
          final delta = measured - expected;
          comparisons.add({
            'recording': session.notes,
            'reference': reference.label,
            'manualReference': reference.manual,
            'maxGpsIntervalSeconds': estimator.maxGpsInterval.inSeconds,
            'overlapStartSeconds': points.first.seconds,
            'overlapEndSeconds': points.last.seconds,
            'estimatedMeters': measured,
            'referenceMeters': expected,
            'deltaMeters': delta,
            'deltaPercent': expected == 0 ? null : 100 * delta / expected,
          });
        }
      }
    }

    String number(Object? value, [int digits = 2]) =>
        value is num ? value.toStringAsFixed(digits) : '—';
    String cell(Object? value) => '$value'.replaceAll('|', r'\|');
    final report = StringBuffer('''# GPS interval comparison

Run: `flutter test tool/compare_gps_gaps.dart --reporter expanded`

All ${sessions.length} repository recordings, using the production estimator and
the Lab replay. Fallback remains at 5 s in every variant. GPS accuracy <= 10 m,
speed <= 3 m/s, calibration >= 15 s / 10 steps / 10 m, default stride 0.70 m.
Only the maximum accepted GPS interval changes. Recorded reference samples never
enter the estimator. Deltas use the shared time interval, exactly as in the Lab.
Watch references are comparison measurements, not ground truth. Manual routes
assume constant speed and are reported separately. No-reference recordings still
appear in the distance/diagnostic table.

## Aggregate reference errors

Mean absolute error (MAE) and mean absolute percentage error (MAPE) give equal
weight to each recording/reference pair within its group.

| Reference kind | GPS limit (s) | Pairs | MAE (m) | MAPE (%) |
| --- | ---: | ---: | ---: | ---: |
''');
    for (final manual in [false, true]) {
      for (final gap in [5, 10, 15]) {
        final rows = comparisons.where(
          (r) =>
              r['manualReference'] == manual &&
              r['maxGpsIntervalSeconds'] == gap,
        );
        if (rows.isEmpty) continue;
        final mae =
            rows.fold(
              0.0,
              (sum, r) => sum + (r['deltaMeters'] as double).abs(),
            ) /
            rows.length;
        final percentages = rows
            .map((r) => r['deltaPercent'])
            .whereType<double>();
        final mape = percentages.isEmpty
            ? null
            : percentages.fold(0.0, (sum, p) => sum + p.abs()) /
                  percentages.length;
        report.writeln(
          '| ${manual ? 'Manual' : 'Watch'} | $gap | ${rows.length} | '
          '${number(mae)} | ${number(mape)} |',
        );
      }
    }
    report.write('''
## Per-recording distance and diagnostics

Totals span the entire recording, so compare them to the overlap reference
distances in the next table only when the intervals match. "Updates" includes
the first learned stride and subsequent smoothed updates. Rejections count GPS
segments over the time limit, unusable accuracy fixes and excessive segment
speed respectively; coordinate failures are available in the JSON diagnostics.

| Recording | GPS limit (s) | Total (m) | GPS (m) | Steps (m) | Learned | Stride (m) | Updates | Gap rejects | Accuracy rejects | Speed rejects |
| --- | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
''');
    for (final run in runs) {
      final info = run['diagnostics'] as Map<String, String>;
      report.writeln(
        '| ${cell(run['recording'])} | ${run['maxGpsIntervalSeconds']} | '
        '${number(run['distanceMeters'])} | ${info['GPS distance']} | '
        '${info['Step distance']} | ${run['learned']} | '
        '${number(run['stepLengthMeters'], 3)} | ${info['Calibration updates']} | '
        '${info['Rejected GPS gap']} | ${info['Rejected GPS accuracy']} | '
        '${info['Rejected GPS speed']} |',
      );
    }
    report.write('''
## Per-reference comparison over shared time

| Recording | Reference | GPS limit (s) | Overlap (s) | Estimate (m) | Reference (m) | Delta (m) | Delta (%) |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
''');
    for (final row in comparisons) {
      report.writeln(
        '| ${cell(row['recording'])} | ${cell(row['reference'])} | '
        '${row['maxGpsIntervalSeconds']} | '
        '${number(row['overlapStartSeconds'])}–${number(row['overlapEndSeconds'])} | '
        '${number(row['estimatedMeters'])} | ${number(row['referenceMeters'])} | '
        '${number(row['deltaMeters'])} | ${number(row['deltaPercent'])} |',
      );
    }
    final output = await Directory('build').create(recursive: true);
    await File('${output.path}/gps_gap_comparison.md').writeAsString('$report');
    await File('${output.path}/gps_gap_comparison.json').writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'runs': runs, 'comparisons': comparisons}),
    );
    // The concise runner output points to the complete, reproducible comparison.
    // ignore: avoid_print
    print(
      'Compared ${sessions.length} recordings: build/gps_gap_comparison.md',
    );
  });
}
