import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_live_activity_service.dart';
import 'dart:async';

class RecordingLiveActivityService extends WalkLiveActivityService {
  final calls = <String>[];
  final starts = <({DateTime startedAt, DateTime endsAt})>[];

  Completer<bool>? pendingStart;

  @override
  Future<bool> start({
    required DateTime startedAt,
    required DateTime endsAt,
  }) async {
    calls.add('start');
    starts.add((startedAt: startedAt, endsAt: endsAt));

    final pending = pendingStart;
    if (pending != null) return await pending.future;
    return true;
  }

  @override
  Future<void> end() async {
    calls.add('end');
  }
}

void main() {
  for (final abort in [false, true]) {
    test('starts once across ticks and ends on '
        '${abort ? 'abort' : 'completion'}', () {
      fakeAsync((async) {
        var now = DateTime.utc(2026, 11, 15, 10);

        final session = WalkSession(
          sources: [],
          distanceEstimator: GpsDistanceEstimator(),
          walkDuration: const Duration(seconds: 3),
          now: () => now,
        );

        final service = RecordingLiveActivityService();
        final subscription = synchronizeLiveActivity(
          session,
          service,
        ).listen((_) {});

        async.flushMicrotasks();

        expect(service.calls, ['end']);

        session.start();
        async.flushMicrotasks();

        expect(service.calls, ['end', 'end', 'start']);
        expect(service.starts.single, (
          startedAt: now,
          endsAt: now.add(session.walkDuration),
        ));

        now = now.add(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));

        expect(service.starts, hasLength(1));
        expect(service.calls, hasLength(3));

        if (abort) {
          session.abort();
        } else {
          now = now.add(const Duration(seconds: 2));
          async.elapse(const Duration(seconds: 2));
        }

        async.flushMicrotasks();

        expect(service.calls, ['end', 'end', 'start', 'end']);

        session.reset();
        async.flushMicrotasks();

        expect(service.calls, hasLength(4));

        session.start();
        async.flushMicrotasks();

        expect(service.starts, hasLength(2));
        expect(service.calls, ['end', 'end', 'start', 'end', 'end', 'start']);

        subscription.cancel();
        session.dispose();
        async.flushMicrotasks();
      });
    });

    test('processes abort after a pending start completes', () {
      fakeAsync((async) {
        final session = WalkSession(
          sources: [],
          distanceEstimator: GpsDistanceEstimator(),
        );

        final pendingStart = Completer<bool>();
        final service = RecordingLiveActivityService()
          ..pendingStart = pendingStart;

        final subscription = synchronizeLiveActivity(
          session,
          service,
        ).listen((_) {});

        async.flushMicrotasks();

        session.start();
        async.flushMicrotasks();

        expect(service.calls, ['end', 'end', 'start']);

        session.abort();
        async.flushMicrotasks();

        expect(service.calls, ['end', 'end', 'start']);

        pendingStart.complete(true);
        async.flushMicrotasks();

        expect(service.calls, ['end', 'end', 'start', 'end']);

        subscription.cancel();
        session.dispose();
        async.flushMicrotasks();
      });
    });
  }
}
