import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';

// ---------------------------------------------------------------------------
// Test doubles (same as walk_session_test.dart)
// ---------------------------------------------------------------------------

class FakeSensorSource extends SensorSource {
  final StreamController<SensorSample> controller =
      StreamController<SensorSample>.broadcast();

  @override
  String get sourceId => 'fake';
  @override
  Stream<SensorSample> get samples => controller.stream;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

SensorSample _position(double lat, double lng) => SensorSample(
  timestamp: DateTime.now(),
  sourceId: 'fake',
  type: SampleType.position,
  values: {
    PositionKeys.latitude: lat,
    PositionKeys.longitude: lng,
    PositionKeys.accuracy: 0,
  },
);

// ---------------------------------------------------------------------------
// Tests for the deduplicatedSaves function in walk_session_provider.dart
// ---------------------------------------------------------------------------

void main() {
  group('deduplicatedSaves', () {
    test('persists optional phone steps and a downward stride correction', () {
      fakeAsync((async) {
        final gps = FakeSensorSource();
        final phone = FakeSensorSource();
        final estimator = GpsStepDistanceEstimator(stepSourceId: 'fake');
        final session = WalkSession(
          sources: [gps],
          optionalSources: [phone],
          distanceEstimator: estimator,
          walkDuration: const Duration(seconds: 60),
        )..profileId = 1;
        final rows = <WalkSessionRow>[];
        final sub = deduplicatedSaves(session).listen(rows.add);
        final epoch = DateTime.utc(2026);

        void steps(int second, double count) {
          phone.controller.add(
            SensorSample(
              timestamp: epoch.add(Duration(seconds: second)),
              sourceId: 'fake',
              type: SampleType.steps,
              values: {StepKeys.cumulativeSteps: count},
            ),
          );
          async.flushMicrotasks();
        }

        session.start();
        async.flushMicrotasks();
        steps(0, 1000);
        steps(10, 1010);
        expect(session.state.distance, closeTo(7, 1e-6));
        expect(rows.last.distance, closeTo(7, 1e-6));

        for (var i = 0; i <= 17; i++) {
          gps.controller.add(
            SensorSample(
              timestamp: epoch.add(Duration(seconds: 10 + i)),
              sourceId: 'fake',
              type: SampleType.position,
              values: {
                PositionKeys.latitude: 0,
                PositionKeys.longitude:
                    i * 0.6 / Geolocator.distanceBetween(0, 0, 0, 1),
                PositionKeys.accuracy: 3,
              },
            ),
          );
          async.flushMicrotasks();
          steps(10 + i, (1010 + i).toDouble());
        }

        // 10.2 GPS metres plus ten earlier steps corrected from 0.7 to 0.6 m.
        expect(estimator.stepLength, closeTo(0.6, 1e-6));
        expect(session.state.distance, closeTo(16.2, 1e-6));
        expect(rows.last.distance, closeTo(16.2, 1e-6));
        expect(rows[rows.length - 2].distance, closeTo(17.2, 1e-6));
        expect(session.state.lastSamples[SampleType.steps], isNotNull);

        session.abort();
        async.flushMicrotasks();
        expect(rows.last.phase, WalkPhase.aborted);
        expect(rows.last.distance, closeTo(16.2, 1e-6));
        session.start();
        async.flushMicrotasks();
        expect(estimator.hasLearnedStepLength, isFalse);
        steps(30, 2000);
        steps(31, 2002);
        expect(rows.last.distance, closeTo(1.4, 1e-6));

        sub.cancel();
        session.dispose();
        async.flushMicrotasks();
        gps.controller.close();
        phone.controller.close();
      });
    });

    test('skips state emissions that do not change persisted fields', () {
      fakeAsync((async) {
        final source = FakeSensorSource();
        final session = WalkSession(
          sources: [source],
          distanceEstimator: GpsDistanceEstimator(),
          walkDuration: const Duration(seconds: 10),
        )..profileId = 1;

        final rows = <WalkSessionRow>[];
        final sub = deduplicatedSaves(session).listen(rows.add);

        session.start();
        async.flushMicrotasks();
        expect(rows, hasLength(1)); // start → phase changed to running

        // Non-GPS sample changes lastSamples but not distance/duration/phase.
        source.controller.add(
          SensorSample(
            timestamp: DateTime.now(),
            sourceId: 'fake',
            type: SampleType.heartRate,
            values: const {'bpm': 80},
          ),
        );
        async.flushMicrotasks();
        expect(rows, hasLength(1)); // still 1 — no new emission

        // Same GPS position repeated — distance stays 0.
        source.controller.add(_position(48.0, 10.0));
        async.flushMicrotasks();
        source.controller.add(_position(48.0, 10.0));
        async.flushMicrotasks();
        // At most one extra emission (the first position may or may not
        // update internal estimator state), but not two.
        expect(rows.length, lessThanOrEqualTo(2));

        sub.cancel();
        session.dispose();
      });
    });

    test('emits when distance, duration, or phase change', () {
      fakeAsync((async) {
        final source = FakeSensorSource();
        var now = DateTime(2026);
        final session = WalkSession(
          sources: [source],
          distanceEstimator: GpsDistanceEstimator(),
          walkDuration: const Duration(seconds: 3),
          now: () => now,
        )..profileId = 1;

        final rows = <WalkSessionRow>[];
        final sub = deduplicatedSaves(session).listen(rows.add);

        session.start();
        async.flushMicrotasks();
        final afterStart = rows.length;

        // Timer tick → duration changes.
        now = now.add(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));
        expect(rows.length, greaterThan(afterStart));
        expect(rows.last.duration, const Duration(seconds: 1));

        // GPS movement → distance changes.
        final beforeGps = rows.length;
        source.controller.add(_position(0, 0));
        source.controller.add(_position(0, 0.001));
        async.flushMicrotasks();
        expect(rows.length, greaterThan(beforeGps));
        expect(rows.last.distance, greaterThan(0));

        // Let the test finish → phase changes to finished.
        now = now.add(const Duration(seconds: 2));
        async.elapse(const Duration(seconds: 2));
        expect(rows.last.phase, WalkPhase.finished);

        sub.cancel();
        session.dispose();
      });
    });

    test('emits for a new session even when initial values match', () {
      fakeAsync((async) {
        final source = FakeSensorSource();
        final session = WalkSession(
          sources: [source],
          distanceEstimator: GpsDistanceEstimator(),
          walkDuration: const Duration(seconds: 5),
        )..profileId = 1;

        final rows = <WalkSessionRow>[];
        final sub = deduplicatedSaves(session).listen(rows.add);

        // First session: start then abort immediately (distance=0, duration=0).
        session.start();
        async.flushMicrotasks();
        session.abort();
        async.flushMicrotasks();
        final afterFirstSession = rows.length;
        final firstSessionId = rows.first.id;

        // Second session: same initial values but different sessionId.
        session.reset();
        async.flushMicrotasks();
        session.start();
        async.flushMicrotasks();

        expect(rows.length, greaterThan(afterFirstSession));
        expect(rows.last.id, isNot(firstSessionId));

        sub.cancel();
        session.dispose();
      });
    });
  });
}
