import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data_providers.dart';
import '../../core/domain/distance_estimator.dart';
import '../../core/domain/test_session.dart';
import '../../core/sensors/gps_source.dart';
import '../../core/sensors/location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

// Kept alive for the whole app lifetime, so a running test survives
// navigating between screens.
final testSessionProvider = Provider<TestSession>((ref) {
  final session = TestSession(
    sources: [
      GpsSource(locationService: ref.watch(locationServiceProvider)),
    ],
    distanceEstimator: GpsDistanceEstimator(),
    sampleSink: ref.watch(sampleRepositoryProvider),
  );

  // Persist every test that ran, as soon as it ends.
  final testRepository = ref.watch(testRepositoryProvider);
  var previousPhase = session.state.phase;

  final subscription = session.states.listen((state) {
    final wasRunning = previousPhase == TestPhase.running;
    previousPhase = state.phase;

    final endedNow =
        wasRunning &&
        (state.phase == TestPhase.finished || state.phase == TestPhase.aborted);

    final sessionId = state.sessionId;
    final startedAt = state.startedAt;

    if (!endedNow || sessionId == null || startedAt == null) {
      return;
    }

    testRepository.saveResult(
      id: sessionId,
      startedAt: startedAt,
      duration: session.testDuration - state.remainingTime,
      distanceMeters: state.distanceMeters,
      completed: state.phase == TestPhase.finished,
    );
  });

  ref.onDispose(() {
    subscription.cancel();
    session.dispose();
  });

  return session;
});

final testSessionStateProvider = StreamProvider<TestSessionState>(
  (ref) => ref.watch(testSessionProvider).states,
);
