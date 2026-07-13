import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/core/sensors/location_service.dart';

class FakeLocationService extends LocationService {
  FakeLocationService({this.hasPermission = true, Stream<Position>? positions})
    : _positions = positions ?? const Stream.empty();

  final bool hasPermission;
  final Stream<Position> _positions;

  @override
  Future<bool> requestLocationPermission() async => hasPermission;

  @override
  Stream<Position> getPositionStream() => _positions;
}

WalkSession createSession({
  bool hasPermission = true,
  Stream<Position>? positions,
  Duration walkDuration = const Duration(seconds: 3),
}) {
  return WalkSession(
    locationService: FakeLocationService(
      hasPermission: hasPermission,
      positions: positions,
    ),
    distanceEstimator: GpsDistanceEstimator(),
    walkDuration: walkDuration,
  );
}

Position createPosition({required double latitude, required double longitude}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  test('starts in idle phase with full remaining time', () {
    final session = createSession(walkDuration: const Duration(minutes: 6));

    expect(session.state.phase, WalkPhase.idle);
    expect(session.state.remainingTime, const Duration(minutes: 6));
    expect(session.state.distanceMeters, 0);
  });

  test('stays idle with an error message when permission is denied', () {
    fakeAsync((async) {
      final session = createSession(hasPermission: false);

      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.idle);
      expect(session.state.errorMessage, isNotNull);
    });
  });

  test('counts down and finishes after the configured duration', () {
    fakeAsync((async) {
      final session = createSession(walkDuration: const Duration(seconds: 3));

      session.start();
      async.flushMicrotasks();

      expect(session.state.phase, WalkPhase.running);

      async.elapse(const Duration(seconds: 1));
      expect(session.state.remainingTime, const Duration(seconds: 2));

      async.elapse(const Duration(seconds: 2));
      expect(session.state.phase, WalkPhase.finished);
      expect(session.state.remainingTime, Duration.zero);
    });
  });

  test('accumulates distance from incoming positions', () {
    fakeAsync((async) {
      final positions = StreamController<Position>();
      final session = createSession(positions: positions.stream);

      session.start();
      async.flushMicrotasks();

      positions.add(createPosition(latitude: 0, longitude: 0));
      positions.add(createPosition(latitude: 0, longitude: 0.001));
      async.flushMicrotasks();

      expect(session.state.distanceMeters, closeTo(111, 2));
      expect(session.state.currentPosition, isNotNull);
    });
  });

  test('abort stops the test and keeps the distance', () {
    fakeAsync((async) {
      final positions = StreamController<Position>();
      final session = createSession(positions: positions.stream);

      session.start();
      async.flushMicrotasks();

      positions.add(createPosition(latitude: 0, longitude: 0));
      positions.add(createPosition(latitude: 0, longitude: 0.001));
      async.flushMicrotasks();

      session.abort();

      expect(session.state.phase, WalkPhase.aborted);
      expect(session.state.distanceMeters, greaterThan(0));

      // Timer must be cancelled: elapsing time changes nothing anymore.
      final remainingAfterAbort = session.state.remainingTime;
      async.elapse(const Duration(seconds: 5));
      expect(session.state.remainingTime, remainingAfterAbort);
    });
  });

  test('reset returns to idle with full remaining time', () {
    fakeAsync((async) {
      final session = createSession(walkDuration: const Duration(seconds: 3));

      session.start();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));

      session.reset();

      expect(session.state.phase, WalkPhase.idle);
      expect(session.state.remainingTime, const Duration(seconds: 3));
      expect(session.state.distanceMeters, 0);
    });
  });
}
