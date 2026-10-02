import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimator_comparison.dart';
import 'package:six_minute_walk_test/features/walk/domain/kalman_gps_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';

import 'walk_session_test.dart'
    show InitialSampleFakeSensorSource, RecordingSink;
import 'kalman_gps_distance_estimator_test.dart' as kalman;

class RecordingEstimator extends DistanceEstimator {
  RecordingEstimator(this.increment);
  final double increment;
  final List<SensorSample> samples = [];
  final Map<String, String> info = {};
  bool fail = false;
  bool failReset = false;
  bool invalidDistance = false;

  @override
  double get totalDistance =>
      invalidDistance ? double.nan : samples.length * increment;
  @override
  Map<String, String> get additionalInfo => info;
  @override
  void addSample(SensorSample sample) {
    if (fail) throw StateError('broken');
    samples.add(sample);
    info['Samples'] = '${samples.length}';
  }

  @override
  void reset() {
    if (failReset) throw StateError('reset failed');
    samples.clear();
    info.clear();
  }
}

SensorSample steps(double count) => SensorSample(
  timestamp: DateTime.utc(2026),
  type: SampleType.steps,
  sourceId: 'steps',
  values: {StepKeys.cumulativeSteps: count},
);

void main() {
  test('Kalman live comparison retains the filtered result at finish', () {
    fakeAsync((async) {
      final initial = kalman.gps(0, 0);
      final source = InitialSampleFakeSensorSource([initial]);
      final comparison = KalmanGpsDistanceEstimator();
      final direct = KalmanGpsDistanceEstimator()..addSample(initial);
      final sink = RecordingSink();
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        comparisonEstimators: [
          NamedDistanceEstimator('Kalman GPS', comparison),
        ],
        sampleSink: sink,
        walkDuration: const Duration(seconds: 20),
      );
      session.start();
      async.flushMicrotasks();
      for (final sample in [
        kalman.gps(5, 7),
        kalman.gps(7, 1000),
        kalman.gps(10, 14),
      ]) {
        direct.addSample(sample);
        source.controller.add(sample);
        async.flushMicrotasks();
        expect(session.state.comparisons.single.distance, direct.totalDistance);
      }
      expect(sink.recorded, hasLength(4));
      expect(session.state.distance, greaterThan(1000));
      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();
      expect(session.state.phase, WalkPhase.finished);
      expect(session.state.comparisons.single.distance, direct.totalDistance);
      expect(
        session.state.comparisons.single.additionalInfo,
        direct.additionalInfo,
      );
      session.dispose();
      async.flushMicrotasks();
    });
  });
  for (final abort in [false, true]) {
    test(
      'comparison lifecycle, ${abort ? 'abort' : 'finish'}, and immutable snapshots',
      () {
        fakeAsync((async) {
          final initial = steps(100);
          final next = steps(110);
          final source = InitialSampleFakeSensorSource([initial]);
          final primary = RecordingEstimator(1);
          final first = RecordingEstimator(2);
          final second = RecordingEstimator(3);
          final sink = RecordingSink();
          final session = WalkSession(
            sources: [source],
            distanceEstimator: primary,
            comparisonEstimators: [
              NamedDistanceEstimator('first', first),
              NamedDistanceEstimator('second', second),
            ],
            sampleSink: sink,
            walkDuration: const Duration(seconds: 3),
            now: () => clock.now(),
          );
          session.warmUp();
          async.flushMicrotasks();
          source.controller.add(next);
          async.flushMicrotasks();
          expect(first.samples, isEmpty);
          expect(sink.recorded, isEmpty);
          session.start();
          async.flushMicrotasks();
          final initialState = session.state;
          source.controller.add(next);
          async.flushMicrotasks();
          for (final estimator in [primary, first, second]) {
            expect(estimator.samples, [initial, next]);
          }
          expect(sink.recorded.length, 2);
          expect(session.state.distance, 2);
          expect(session.state.comparisons.map((r) => r.distance), [4, 6]);
          expect(initialState.comparisons.first.additionalInfo['Samples'], '1');
          async.elapse(const Duration(seconds: 1));
          expect(session.state.comparisons.first.distance, 4);
          source.controller.addError(StateError('sensor'));
          async.flushMicrotasks();
          expect(session.state.comparisons.first.distance, 4);
          if (abort) {
            session.abort();
          } else {
            async.elapse(const Duration(seconds: 2));
          }
          async.flushMicrotasks();
          expect(
            session.state.phase,
            abort ? WalkPhase.aborted : WalkPhase.finished,
          );
          final results = session.state.comparisons;
          session.reset();
          async.flushMicrotasks();
          expect(session.state.comparisons, isEmpty);
          expect(results.first.distance, 4);
          expect(results.first.additionalInfo['Samples'], '2');
          expect(() => results.clear(), throwsUnsupportedError);
          expect(
            () => results.first.additionalInfo.clear(),
            throwsUnsupportedError,
          );
          session.start();
          async.flushMicrotasks();
          expect(session.state.comparisons.first.distance, 2);
          session.dispose();
          async.flushMicrotasks();
        });
      },
    );
  }

  for (final failure in ['sample', 'reset', 'distance']) {
    test('isolates $failure failure and retries on next run', () {
      fakeAsync((async) {
        final source = InitialSampleFakeSensorSource([steps(1)]);
        final broken = RecordingEstimator(2)
          ..fail = failure == 'sample'
          ..failReset = failure == 'reset'
          ..invalidDistance = failure == 'distance';
        final session = WalkSession(
          sources: [source],
          distanceEstimator: RecordingEstimator(1),
          comparisonEstimators: [
            NamedDistanceEstimator('broken', broken),
            NamedDistanceEstimator('healthy', RecordingEstimator(3)),
          ],
        );
        session.start();
        async.flushMicrotasks();
        expect(session.state.isRunning, isTrue);
        expect(session.state.distance, 1);
        expect(session.state.comparisons.first.error, isNotNull);
        expect(session.state.comparisons.last.distance, 3);
        broken
          ..fail = false
          ..failReset = false
          ..invalidDistance = false;
        source.controller.add(steps(2));
        async.flushMicrotasks();
        expect(session.state.comparisons.first.error, isNotNull);
        expect(session.state.comparisons.last.distance, 6);
        session.abort();
        async.flushMicrotasks();
        session.start();
        async.flushMicrotasks();
        expect(session.state.comparisons.first.error, isNull);
        expect(session.state.comparisons.first.distance, 2);
        session.dispose();
        async.flushMicrotasks();
      });
    });
  }

  test('comparison-only changes do not trigger persisted saves', () {
    fakeAsync((async) {
      final source = InitialSampleFakeSensorSource([]);
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        comparisonEstimators: [
          NamedDistanceEstimator('steps', RecordingEstimator(3)),
        ],
      )..profileId = 1;
      final rows = <WalkSessionRow>[];
      final subscription = deduplicatedSaves(session).listen(rows.add);
      session.start();
      async.flushMicrotasks();
      expect(rows.length, 1);
      source.controller.add(steps(100));
      async.flushMicrotasks();
      expect(session.state.comparisons.single.distance, 3);
      expect(rows.length, 1);
      expect(rows.single.distance, 0);
      subscription.cancel();
      session.dispose();
      async.flushMicrotasks();
    });
  });
}
