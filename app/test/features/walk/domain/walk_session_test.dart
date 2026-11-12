import 'package:six_minute_walk_test/core/domain/walk_phase.dart';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/notification_sender.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_completion_notification.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';

import '../../../helpers/fake_sensors.dart';
import '../../../helpers/logs.dart';

class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

/// Records shown and dismissed notifications; can be made to fail.
class FakeNotificationSender implements NotificationSender {
  FakeNotificationSender({this.failing = false});

  final bool failing;
  final List<({int id, String title, String body})> shown = [];
  final List<int> cancelled = [];

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (failing) {
      throw StateError('show failed');
    }
    shown.add((id: id, title: title, body: body));
  }

  @override
  Future<void> cancel({required int id}) async {
    if (failing) {
      throw StateError('cancel failed');
    }
    cancelled.add(id);
  }
}

const _completionNotification = WalkCompletionNotification(
  title: 'Test completed',
  body: 'The six minutes are over.',
);

SensorSample createPositionSample({
  required double latitude,
  required double longitude,
}) {
  return SensorSample(
    timestamp: DateTime.now(),
    sourceId: 'fake',
    type: SampleType.position,
    values: {
      PositionKeys.latitude: latitude,
      PositionKeys.longitude: longitude,
      PositionKeys.accuracy: 0,
    },
  );
}

void main() {
  test('starts in idle phase with full remaining time', () {
    final session = WalkSession(
      sources: [FakeSensorSource()],
      distanceEstimator: GpsDistanceEstimator(),
      walkDuration: const Duration(minutes: 6),
    );

    expect(session.state.phase, WalkPhase.idle);
    expect(session.state.remainingTime, const Duration(minutes: 6));
    expect(session.state.distance, 0);
  });

  test('stays idle with an error message when a source is unavailable', () {
    silenceLogs();
    fakeAsync((async) {
      final session = WalkSession(
        sources: [FakeSensorSource(available: false)],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 3),
      );

      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.idle);
      expect(session.state.error?.issue, SensorIssue.unavailable);
      expect(session.state.error?.detail, 'sensor unavailable');
    });
  });

  test('warms up sensors without starting or recording a test', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final sink = RecordingSink();
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        sampleSink: sink,
      );

      session.warmUp();
      async.flushMicrotasks();
      source.controller.add(createPositionSample(latitude: 0, longitude: 0));
      async.flushMicrotasks();

      expect(source.started, isTrue);
      expect(session.state.phase, WalkPhase.idle);
      expect(session.state.sessionId, isNull);
      expect(sink.recorded, isEmpty);
      expect(session.state.lastSamples, isEmpty);
    });
  });

  test('uses warmed-up sensors when the test starts', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
      );

      session.warmUp();
      async.flushMicrotasks();
      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.running);
      expect(source.startCalls, 1);
    });
  });

  test('records initial samples when a warmed-up test starts', () {
    fakeAsync((async) {
      final initialPosition = createPositionSample(
        latitude: 48.422,
        longitude: 9.956,
      );
      final initialSteps = SensorSample(
        timestamp: DateTime.now(),
        sourceId: 'fake',
        type: SampleType.steps,
        values: const {StepKeys.cumulativeSteps: 1000},
      );
      final source = InitialSampleFakeSensorSource([
        initialPosition,
        initialSteps,
      ]);
      final sink = RecordingSink();
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        sampleSink: sink,
      );

      session.warmUp();
      async.flushMicrotasks();
      session.start();
      async.flushMicrotasks();

      expect(source.startCalls, 1);
      expect(source.initialSampleCalls, 1);
      expect(sink.recorded.map((entry) => entry.$2), [
        same(initialPosition),
        same(initialSteps),
      ]);
      expect(
        session.state.lastSamples[SampleType.position],
        same(initialPosition),
      );
      expect(session.state.lastSamples[SampleType.steps], same(initialSteps));
      expect(session.state.distance, 0);
    });
  });

  test('stops sensors when warm-up is no longer needed', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
      );

      session.warmUp();
      async.flushMicrotasks();
      session.stopWarmUp();
      async.flushMicrotasks();

      expect(source.stopped, isTrue);
    });
  });

  test('counts down and finishes after the configured duration', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final clock = TestClock(DateTime(2026));
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 3),
        now: clock.call,
      );

      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.running);
      expect(session.state.startedAt!.isUtc, isTrue);
      expect(source.started, isTrue);

      clock.advance(const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 1));
      expect(session.state.remainingTime, const Duration(seconds: 2));

      clock.advance(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 2));
      expect(session.state.phase, WalkPhase.finished);
      expect(session.state.remainingTime, Duration.zero);
      expect(source.stopped, isTrue);
    });
  });

  test('uses elapsed wall-clock time when a timer callback is delayed', () {
    fakeAsync((async) {
      final clock = TestClock(DateTime(2026));
      final session = WalkSession(
        sources: [FakeSensorSource()],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 3),
        now: clock.call,
      );

      session.start();
      async.flushMicrotasks();

      // Simulate the app being paused for longer than the test duration before
      // the next periodic callback is allowed to run.
      clock.advance(const Duration(seconds: 4));
      async.elapse(const Duration(seconds: 1));

      expect(session.state.phase, WalkPhase.finished);
      expect(session.state.remainingTime, Duration.zero);
    });
  });

  test('synchronizes the countdown with the wall clock after resuming', () {
    fakeAsync((async) {
      final clock = TestClock(DateTime(2026));
      final session = WalkSession(
        sources: [FakeSensorSource()],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 5),
        now: clock.call,
      );

      session.start();
      async.flushMicrotasks();

      // Simulate time passing while the app is backgrounded and Dart timers
      // are paused. No timer callback or sensor event occurs in this period.
      clock.advance(const Duration(seconds: 2));
      session.synchronizeWithClock();

      expect(session.state.phase, WalkPhase.running);
      expect(session.state.remainingTime, const Duration(seconds: 3));

      clock.advance(const Duration(seconds: 3));
      session.synchronizeWithClock();

      expect(session.state.phase, WalkPhase.finished);
      expect(session.state.remainingTime, Duration.zero);
    });
  });

  test('counts wall-clock time while periodic callbacks are delayed', () {
    fakeAsync((async) {
      final clock = TestClock(DateTime(2026));
      final session = WalkSession(
        sources: [FakeSensorSource()],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 5),
        now: clock.call,
      );

      session.start();
      async.flushMicrotasks();

      clock.advance(const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 1));
      expect(session.state.remainingTime, const Duration(seconds: 4));

      // The app is effectively paused: wall-clock time advances while the
      // periodic callback does not run.
      clock.advance(const Duration(seconds: 2));

      async.elapse(const Duration(seconds: 1));
      expect(session.state.remainingTime, const Duration(seconds: 2));
    });
  });

  test('accumulates distance and forwards every sample to the sink', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final sink = RecordingSink();
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        sampleSink: sink,
        walkDuration: const Duration(seconds: 30),
      );

      session.start();
      async.flushMicrotasks();

      source.controller.add(createPositionSample(latitude: 0, longitude: 0));
      source.controller.add(
        createPositionSample(latitude: 0, longitude: 0.001),
      );
      async.flushMicrotasks();

      expect(session.state.distance, closeTo(111, 2));
      expect(session.state.lastSamples[SampleType.position], isNotNull);

      expect(sink.recorded, hasLength(2));
      expect(sink.recorded.first.$1, session.state.sessionId);
    });
  });

  test('ignores a GPS sample received after the deadline', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final sink = RecordingSink();
      final clock = TestClock(DateTime(2026));
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        sampleSink: sink,
        walkDuration: const Duration(seconds: 3),
        now: clock.call,
      );

      session.start();
      async.flushMicrotasks();

      source.controller.add(createPositionSample(latitude: 0, longitude: 0));
      source.controller.add(
        createPositionSample(latitude: 0, longitude: 0.001),
      );
      async.flushMicrotasks();
      final distanceAtDeadline = session.state.distance;

      clock.advance(const Duration(seconds: 3));
      source.controller.add(
        createPositionSample(latitude: 0, longitude: 0.002),
      );
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.finished);
      expect(session.state.remainingTime, Duration.zero);
      expect(session.state.distance, distanceAtDeadline);
      expect(sink.recorded, hasLength(2));
    });
  });

  test('an unavailable optional source does not prevent the test', () {
    fakeAsync((async) {
      final optionalSource = FakeSensorSource(available: false);
      final session = WalkSession(
        sources: [FakeSensorSource()],
        optionalSources: [optionalSource],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 3),
      );

      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.running);
      expect(session.state.error, isNull);
    });
  });

  test('samples from optional sources reach the sink', () {
    fakeAsync((async) {
      final optionalSource = FakeSensorSource();
      final sink = RecordingSink();
      final session = WalkSession(
        sources: [FakeSensorSource()],
        optionalSources: [optionalSource],
        distanceEstimator: GpsDistanceEstimator(),
        sampleSink: sink,
        walkDuration: const Duration(seconds: 30),
      );

      session.start();
      async.flushMicrotasks();

      optionalSource.controller.add(
        SensorSample(
          timestamp: DateTime.now(),
          sourceId: 'fake',
          type: SampleType.heartRate,
          values: const {"bpm": 98},
        ),
      );
      async.flushMicrotasks();

      expect(sink.recorded, hasLength(1));
      expect(session.state.lastSamples[SampleType.heartRate], isNotNull);

      // Distance must be unaffected by non-position samples.
      expect(session.state.distance, 0);
    });
  });

  test('flushes the sink when the test ends', () {
    fakeAsync((async) {
      final sink = RecordingSink();
      final clock = TestClock(DateTime(2026));
      final session = WalkSession(
        sources: [FakeSensorSource()],
        distanceEstimator: GpsDistanceEstimator(),
        sampleSink: sink,
        walkDuration: const Duration(seconds: 2),
        now: clock.call,
      );

      session.start();
      async.flushMicrotasks();

      clock.advance(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 2));

      expect(session.state.phase, WalkPhase.finished);
      expect(sink.flushCount, greaterThan(0));
    });
  });

  test('abort stops the test and keeps the distance', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 30),
      );

      session.start();
      async.flushMicrotasks();

      source.controller.add(createPositionSample(latitude: 0, longitude: 0));
      source.controller.add(
        createPositionSample(latitude: 0, longitude: 0.001),
      );
      async.flushMicrotasks();

      session.abort();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.aborted);
      expect(session.state.distance, greaterThan(0));
      expect(source.stopped, isTrue);

      // Timer must be cancelled: elapsing time changes nothing anymore.
      final remainingAfterAbort = session.state.remainingTime;
      async.elapse(const Duration(seconds: 5));
      expect(session.state.remainingTime, remainingAfterAbort);
    });
  });

  test('reset returns to idle with full remaining time', () {
    fakeAsync((async) {
      final clock = TestClock(DateTime(2026));
      final session = WalkSession(
        sources: [FakeSensorSource()],
        distanceEstimator: GpsDistanceEstimator(),
        walkDuration: const Duration(seconds: 3),
        now: clock.call,
      );

      session.start();
      async.flushMicrotasks();
      clock.advance(const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 1));

      session.reset();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.idle);
      expect(session.state.remainingTime, const Duration(seconds: 3));
      expect(session.state.distance, 0);
    });
  });

  group('completion notification', () {
    late TestClock clock;
    late FakeNotificationSender sender;

    WalkSession createSession({FakeSensorSource? source}) {
      return WalkSession(
        sources: [source ?? FakeSensorSource()],
        distanceEstimator: GpsDistanceEstimator(),
        notificationSender: sender,
        walkDuration: const Duration(seconds: 3),
        now: clock.call,
      );
    }

    void elapse(FakeAsync async, Duration duration) {
      clock.advance(duration);
      async.elapse(duration);
    }

    setUp(() {
      clock = TestClock(DateTime(2026));
      sender = FakeNotificationSender();
    });

    test('is shown once when the test ends regularly', () {
      fakeAsync((async) {
        final session = createSession();

        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();

        elapse(async, const Duration(seconds: 2));
        expect(sender.shown, isEmpty);

        // Keep elapsing past the deadline: further ticks must not repeat it.
        elapse(async, const Duration(seconds: 3));

        expect(session.state.phase, WalkPhase.finished);
        expect(sender.shown, hasLength(1));
        expect(sender.shown.single.title, _completionNotification.title);
        expect(sender.shown.single.body, _completionNotification.body);
      });
    });

    test('is shown when a late sample detects the end first', () {
      fakeAsync((async) {
        final source = FakeSensorSource();
        final session = createSession(source: source);

        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();

        // The clock passes the deadline before the next timer tick.
        clock.advance(const Duration(seconds: 4));
        source.controller.add(createPositionSample(latitude: 0, longitude: 0));
        async.flushMicrotasks();

        expect(session.state.phase, WalkPhase.finished);
        expect(sender.shown, hasLength(1));

        async.elapse(const Duration(seconds: 1));
        expect(sender.shown, hasLength(1));
      });
    });

    test('is not shown when the test is aborted', () {
      fakeAsync((async) {
        final session = createSession();

        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();
        elapse(async, const Duration(seconds: 1));

        session.abort();
        async.flushMicrotasks();
        elapse(async, const Duration(seconds: 5));

        expect(session.state.phase, WalkPhase.aborted);
        expect(sender.shown, isEmpty);
      });
    });

    test('is not shown when a running test is reset', () {
      fakeAsync((async) {
        final session = createSession();

        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();
        elapse(async, const Duration(seconds: 1));

        session.reset();
        async.flushMicrotasks();
        elapse(async, const Duration(seconds: 5));

        expect(session.state.phase, WalkPhase.idle);
        expect(sender.shown, isEmpty);
      });
    });

    test('is shown when stopping exactly at the deadline', () {
      fakeAsync((async) {
        final session = createSession();

        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();

        // The deadline has passed, but no tick has detected it yet.
        clock.advance(const Duration(seconds: 3));
        session.abort();
        async.flushMicrotasks();

        expect(session.state.phase, WalkPhase.finished);
        expect(sender.shown, hasLength(1));
      });
    });

    test('is not shown without notification content', () {
      fakeAsync((async) {
        final session = createSession();

        session.start();
        async.flushMicrotasks();
        elapse(async, const Duration(seconds: 4));

        expect(session.state.phase, WalkPhase.finished);
        expect(sender.shown, isEmpty);
      });
    });

    test('dismisses the previous notification when a new test starts', () {
      fakeAsync((async) {
        final session = createSession();

        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();
        elapse(async, const Duration(seconds: 4));
        expect(sender.cancelled, hasLength(1));

        session.reset();
        async.flushMicrotasks();
        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();

        expect(sender.cancelled, hasLength(2));
        expect(sender.cancelled.last, sender.shown.single.id);
      });
    });

    test('failures do not affect the measurement', () {
      silenceLogs();

      fakeAsync((async) {
        sender = FakeNotificationSender(failing: true);
        final source = FakeSensorSource();
        final session = createSession(source: source);

        session.start(completionNotification: _completionNotification);
        async.flushMicrotasks();
        expect(session.state.phase, WalkPhase.running);

        elapse(async, const Duration(seconds: 4));

        expect(session.state.phase, WalkPhase.finished);
        expect(session.state.error, isNull);
        expect(source.stopped, isTrue);
      });
    });
  });
}
