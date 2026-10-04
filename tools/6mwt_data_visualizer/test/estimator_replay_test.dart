import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart' as app;
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/gps_step_distance_estimator.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/core/domain/sensor_sample.dart';
import 'package:six_mwt_visualizer/core/domain/session.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/experimental_estimators.dart';

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

void main() {
  test('lab compares 5, 10 and 15 s GPS intervals with distinct labels', () {
    final variants = createEstimators()
        .whereType<GpsStepDistanceEstimator>()
        .toList();
    expect(variants.map((e) => e.maxGpsInterval.inSeconds), [5, 10, 15]);
    expect(
      variants.every((e) => e.gpsFallbackTimeout == const Duration(seconds: 5)),
      isTrue,
    );
    final replay = EstimatorReplay(
      session([gps(0, 0), steps(0, 1000), gps(10, 0.00005), steps(10, 1010)]),
    );
    final results = variants.map(replay.run).toList();
    expect(results.map((r) => r.name).toSet(), hasLength(3));
    expect(results.first.additionalInfo['Rejected GPS gap'], '1');
    expect(results[1].additionalInfo['Rejected GPS gap'], '0');
    expect(results[2].additionalInfo['Rejected GPS gap'], '0');
    expect(results.first.distance, closeTo(7, 1e-6));
    expect(results[1].distance, closeTo(5.56, 0.01));
    expect(results[2].distance, closeTo(results[1].distance!, 1e-6));
  });

  test('chart connects distance updates without unrelated sensor plateaus', () {
    final replay = EstimatorReplay(
      session([
        gps(0, 0),
        steps(4, 100),
        steps(9, 101),
        gps(10, 0.0001),
        steps(19, 102),
        gps(20, 0.0002),
        steps(25, 103),
      ]),
    );
    final result = replay.run(GpsDistanceEstimator());
    expect(result.points.map((point) => point.seconds), [
      0,
      4,
      9,
      10,
      19,
      20,
      25,
    ]);
    expect(result.chartPoints.map((point) => point.seconds), [0, 10, 20, 25]);
    expect(
      interpolateDistance(result.chartPoints, 5),
      closeTo(result.points[3].meters / 2, 1e-9),
    );
    expect(result.chartPoints.last.meters, result.distance);
  });

  test('chart preserves empty and stationary recordings', () {
    expect(const ReplayResult('empty', []).chartPoints, isEmpty);
    const stationary = ReplayResult('stationary', [
      DistancePoint(0, 0),
      DistancePoint(5, 0),
      DistancePoint(10, 0),
    ]);
    expect(stationary.chartPoints.map((point) => point.seconds), [0, 10]);
  });

  test(
    'arbitrary diagnostics are captured after replay and survive estimator reset',
    () {
      final estimator = RecordingEstimator();
      final replay = EstimatorReplay(session([gps(0, 0), gps(10, 0.0001)]));
      final result = replay.run(estimator);
      expect(result.additionalInfo, {'Samples seen': '2'});
      estimator.reset();
      expect(result.additionalInfo, {'Samples seen': '2'});
      expect(
        () => result.additionalInfo['changed'] = 'yes',
        throwsUnsupportedError,
      );
    },
  );

  test(
    'replay sorts stably, uses recorded UTC timestamps and preserves all sensor fields',
    () {
      final data = session([
        steps(10, 110),
        gps(0, 0),
        steps(0, 100),
        gps(10, 0.0001),
      ]);
      final replay = EstimatorReplay(data);
      final recording = RecordingEstimator();
      final result = replay.run(recording);
      expect(recording.resetCalled, isTrue);
      expect(recording.seen.map((s) => s.type), [
        app.SampleType.position,
        app.SampleType.steps,
        app.SampleType.steps,
        app.SampleType.position,
      ]);
      expect(recording.seen[1].timestamp, start);
      expect(recording.seen[1].sourceId, 'pedometer');
      expect(recording.seen[1].values, {'cumulative_steps': 100});
      expect(result.points.map((p) => p.seconds), [0, 10]);
      expect(result.distance, 4);
      expect(data.samples.first.timestamp.isUtc, isTrue);
    },
  );

  test(
    'production baseline equals direct app estimator and repeated runs are isolated',
    () {
      final replay = EstimatorReplay(
        session([gps(0, 0), steps(1, 100), gps(10, 0.001)]),
      );
      final direct = GpsDistanceEstimator();
      replay.samples.forEach(direct.addSample);
      final definition = GpsDistanceEstimator();
      expect(replay.run(definition).distance, direct.totalDistance);
      expect(replay.run(definition).distance, direct.totalDistance);
      expect(direct.totalDistance, closeTo(111.32, 0.01));
    },
  );

  test(
    'GPS filter rejects spikes and inaccurate fixes without poisoning anchor',
    () {
      final replay = EstimatorReplay(
        session([
          gps(0, 0),
          gps(1, 1),
          gps(2, 0.00001, accuracy: 100),
          gps(10, 0.0001),
        ]),
      );
      final result = replay.run(
        FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
      );
      expect(result.additionalInfo['Rejected GPS'], '2');
      expect(result.distance, closeTo(11.12, 0.1));
    },
  );

  test(
    'step estimator handles nonzero baselines, reset, status events and multiple sources',
    () {
      final replay = EstimatorReplay(
        session([
          steps(0, 100),
          steps(1, 104),
          steps(2, 900, source: 'watch'),
          steps(3, 2),
          steps(4, 5),
          SensorSample(
            id: 9,
            timestamp: start.add(const Duration(seconds: 5)),
            type: SampleType.steps,
            sourceId: 'pedometer',
            values: {'pedestrian_status': 1},
          ),
        ]),
      );
      final estimator = StepDistanceEstimator(stepLength: 0.5);
      final result = replay.run(estimator);
      expect(result.distance, 3.5);
      expect(replay.run(estimator).distance, 3.5);
    },
  );

  test(
    'reference interpolates exact replay boundaries and is never fed into estimator',
    () {
      final ref = session([
        gps(-5, 0, distance: 100),
        gps(5, 0.001, distance: 120),
        gps(15, 0.002, distance: 160),
      ]);
      final replay = EstimatorReplay(
        session([gps(0, 0), gps(10, 0.0001)], reference: ref),
      );
      expect(replay.reference!.map((p) => p.seconds), [0, 5, 10]);
      expect(replay.reference!.map((p) => p.meters), [0, 10, 30]);
      expect(replay.samples, hasLength(2));
    },
  );

  test(
    'reference without distance uses GPS and partial coverage remains visible',
    () {
      final complete = session([gps(0, 0), gps(10, 0.001)]);
      final replay = EstimatorReplay(
        session([gps(0, 0), gps(10, 0.0001)], reference: complete),
      );
      expect(replay.reference!.last.meters, closeTo(111.2, 0.1));
      final partial = session([gps(1, 0), gps(9, 0.001)]);
      expect(
        EstimatorReplay(
          session([gps(0, 0), gps(10, 0.0001)], reference: partial),
        ).reference!.map((point) => point.seconds),
        [1, 9],
      );
    },
  );

  test('reference entirely outside the replay window is unavailable', () {
    for (final bounds in [(-10, -1), (11, 20)]) {
      final replay = EstimatorReplay(
        session([
          gps(0, 0),
          gps(10, 0.0001),
        ], reference: session([gps(bounds.$1, 0), gps(bounds.$2, 0.001)])),
      );
      expect(replay.reference, isNull);
    }
  });

  test(
    'empty data and failing estimators do not produce misleading successful results',
    () {
      final empty = EstimatorReplay(session([]));
      expect(empty.run(GpsDistanceEstimator()).distance, isNull);
      final replay = EstimatorReplay(session([gps(0, 0)]));
      expect(replay.run(BrokenEstimator()).error, contains('broken'));
      expect(replay.run(GpsDistanceEstimator()).distance, 0);
    },
  );

  test(
    'all repository recordings replay with finite results and sensible duration',
    () async {
      final data = Directory('../../data');
      expect(data.existsSync(), isTrue);
      final loaded = await SessionLoader.loadFromDataDirectory(data.path);
      expect(loaded.sessions, isNotEmpty);
      for (final recording in loaded.sessions) {
        final replay = EstimatorReplay(recording);
        expect(
          replay.duration,
          lessThan(recording.duration + 120),
          reason: recording.notes,
        );
        if (recording.hasReference) {
          expect(replay.reference, isNotNull, reason: recording.notes);
          expect(
            replay.reference!.last.meters,
            greaterThan(0),
            reason: recording.notes,
          );
        }
        for (final estimator in createEstimators()) {
          final result = replay.run(estimator);
          expect(
            result.error,
            isNull,
            reason: '${recording.notes}: ${estimator.runtimeType}',
          );
          expect(result.distance?.isFinite, isTrue, reason: recording.notes);
        }
      }
    },
  );
}
