import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/gps_step_distance_estimator.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';

import '../tool/benchmark_support.dart';
import 'estimator_replay_test.dart' as fixtures;

void main() {
  test(
    'loads each device exactly once, including folders without session.json',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'benchmark-recordings',
      );
      addTearDown(() => root.delete(recursive: true));
      for (final path in [
        'a/session.json',
        'b/session_phone.json',
        'b/session_watch.json',
      ]) {
        final file = File('${root.path}/$path');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          jsonEncode(
            fixtures.session([
              fixtures.gps(0, 0),
              fixtures.gps(10, .0001),
            ]).toReferenceJson(),
          ),
        );
      }
      final recordings = await loadBenchmarkRecordings(root.path);
      expect(recordings, hasLength(3));
      expect(recordings.every((s) => !s.isGroup), isTrue);
      expect(recordings.map((s) => s.recordingLabel), [
        'a/session.json · test',
        'b/session_phone.json · test',
        'b/session_watch.json · test',
      ]);
    },
  );

  test('production factory uses the phone source and production defaults', () {
    final estimator = createProductionEstimator();
    expect(estimator.stepSourceId, PedometerSource.id);
    expect(estimator.maxGpsInterval, GpsStepDistanceEstimator.maxGpsGap);
    expect(estimator.gpsFallbackTimeout, GpsStepDistanceEstimator.maxGpsGap);
  });

  const result = ReplayResult('test estimator', [
    DistancePoint(0, 0),
    DistancePoint(20, 40),
  ]);

  for (final partial in [false, true]) {
    test('compares ${partial ? 'partial' : 'full'} overlap', () {
      final recording = fixtures.session(
        [fixtures.gps(0, 0), fixtures.gps(20, .0002)],
        reference: fixtures.session([
          fixtures.gps(partial ? 5 : 0, 0, distance: 100),
          fixtures.gps(partial ? 15 : 20, .0001, distance: 110),
        ]),
      );
      final row = compareReferences(
        recording,
        EstimatorReplay(recording),
        result,
      ).single;
      expect(row['status'], 'compared');
      expect(row['coveragePercent'], partial ? 50 : 100);
      expect(row['estimatedMeters'], partial ? 20 : 40);
      expect(row['referenceMeters'], 10);
      expect(row['deltaMeters'], partial ? 10 : 30);
      expect(row['absoluteErrorMeters'], partial ? 10 : 30);
      expect(row['deltaPercent'], partial ? 100 : 300);
    });
  }

  test('missing reference and disjoint reference remain explicit', () {
    final recording = fixtures.session([
      fixtures.gps(0, 0),
      fixtures.gps(20, .0002),
    ]);
    final missing = compareReferences(
      recording,
      EstimatorReplay(recording),
      result,
    ).single;
    expect(missing['status'], 'no reference');
    final disjoint = recording.copyWith(
      references: [
        fixtures.session([fixtures.gps(30, 0), fixtures.gps(40, .0001)]),
      ],
    );
    final row = compareReferences(
      disjoint,
      EstimatorReplay(disjoint),
      result,
    ).single;
    expect(row['status'], 'no usable overlap');
    expect(summarizeComparisons([missing, row])['pairs'], 0);
  });

  test('zero reference has absolute error but no percentage error', () {
    final recording = fixtures.session(
      [fixtures.gps(0, 0), fixtures.gps(20, .0002)],
      reference: fixtures.session([
        fixtures.gps(0, 0, distance: 100),
        fixtures.gps(20, 0, distance: 100),
      ]),
    );
    final row = compareReferences(
      recording,
      EstimatorReplay(recording),
      result,
    ).single;
    expect(row['deltaPercent'], isNull);
    expect(summarizeComparisons([row]), {
      'pairs': 1,
      'percentagePairs': 0,
      'maeMeters': 40.0,
      'mapePercent': null,
    });
  });

  test('manual and device reference aggregates stay separate', () {
    final rows = <Map<String, Object?>>[
      {
        'estimator': 'test',
        'manualReference': true,
        'status': 'compared',
        'absoluteErrorMeters': 10.0,
        'deltaPercent': -20.0,
      },
      {
        'estimator': 'test',
        'manualReference': false,
        'status': 'compared',
        'absoluteErrorMeters': 30.0,
        'deltaPercent': 60.0,
      },
    ];
    final lines = summaryLines(rows);
    expect(lines, hasLength(2));
    expect(lines[0], startsWith('device | test |'));
    expect(lines[0], contains('maeMeters: 30.0'));
    expect(lines[1], startsWith('manual | test |'));
    expect(lines[1], contains('maeMeters: 10.0'));
  });
}
