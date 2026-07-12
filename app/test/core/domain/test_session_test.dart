import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/core/domain/sample_sink.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/domain/test_session.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';

class FakeSensorSource implements SensorSource {
  FakeSensorSource({this.available = true});

  final bool available;
  final StreamController<SensorSample> controller =
      StreamController<SensorSample>.broadcast();

  bool started = false;
  bool stopped = false;

  @override
  String get id => 'fake';

  @override
  Stream<SensorSample> get samples => controller.stream;

  @override
  Future<void> start() async {
    if (!available) {
      throw const SensorUnavailableException('sensor unavailable');
    }
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

class RecordingSink implements SampleSink {
  final List<(String, SensorSample)> recorded = [];

  @override
  void addSample(String sessionId, SensorSample sample) {
    recorded.add((sessionId, sample));
  }
}

SensorSample createPositionSample({
  required double latitude,
  required double longitude,
}) {
  return SensorSample(
    timestamp: DateTime.now(),
    sensorId: 'fake',
    type: SampleTypes.position,
    values: {
      PositionKeys.latitude: latitude,
      PositionKeys.longitude: longitude,
      PositionKeys.accuracy: 0,
    },
  );
}

void main() {
  test('starts in idle phase with full remaining time', () {
    final session = TestSession(
      sources: [FakeSensorSource()],
      distanceEstimator: GpsDistanceEstimator(),
      testDuration: const Duration(minutes: 6),
    );

    expect(session.state.phase, TestPhase.idle);
    expect(session.state.remainingTime, const Duration(minutes: 6));
    expect(session.state.distanceMeters, 0);
  });

  test('stays idle with an error message when a source is unavailable', () {
    fakeAsync((async) {
      final session = TestSession(
        sources: [FakeSensorSource(available: false)],
        distanceEstimator: GpsDistanceEstimator(),
        testDuration: const Duration(seconds: 3),
      );

      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, TestPhase.idle);
      expect(session.state.errorMessage, 'sensor unavailable');
    });
  });

  test('counts down and finishes after the configured duration', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final session = TestSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        testDuration: const Duration(seconds: 3),
      );

      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, TestPhase.running);
      expect(source.started, isTrue);

      async.elapse(const Duration(seconds: 1));
      expect(session.state.remainingTime, const Duration(seconds: 2));

      async.elapse(const Duration(seconds: 2));
      expect(session.state.phase, TestPhase.finished);
      expect(session.state.remainingTime, Duration.zero);
      expect(source.stopped, isTrue);
    });
  });

  test('accumulates distance and forwards every sample to the sink', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final sink = RecordingSink();
      final session = TestSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        sampleSink: sink,
        testDuration: const Duration(seconds: 30),
      );

      session.start();
      async.flushMicrotasks();

      source.controller.add(createPositionSample(latitude: 0, longitude: 0));
      source.controller.add(
        createPositionSample(latitude: 0, longitude: 0.001),
      );
      async.flushMicrotasks();

      expect(session.state.distanceMeters, closeTo(111, 2));
      expect(session.state.lastPosition, isNotNull);

      expect(sink.recorded, hasLength(2));
      expect(sink.recorded.first.$1, session.state.sessionId);
    });
  });

  test('abort stops the test and keeps the distance', () {
    fakeAsync((async) {
      final source = FakeSensorSource();
      final session = TestSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        testDuration: const Duration(seconds: 30),
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

      expect(session.state.phase, TestPhase.aborted);
      expect(session.state.distanceMeters, greaterThan(0));
      expect(source.stopped, isTrue);

      // Timer must be cancelled: elapsing time changes nothing anymore.
      final remainingAfterAbort = session.state.remainingTime;
      async.elapse(const Duration(seconds: 5));
      expect(session.state.remainingTime, remainingAfterAbort);
    });
  });

  test('reset returns to idle with full remaining time', () {
    fakeAsync((async) {
      final session = TestSession(
        sources: [FakeSensorSource()],
        distanceEstimator: GpsDistanceEstimator(),
        testDuration: const Duration(seconds: 3),
      );

      session.start();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));

      session.reset();
      async.flushMicrotasks();

      expect(session.state.phase, TestPhase.idle);
      expect(session.state.remainingTime, const Duration(seconds: 3));
      expect(session.state.distanceMeters, 0);
    });
  });
}
