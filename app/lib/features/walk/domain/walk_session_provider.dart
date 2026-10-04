import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/sensors/gps_source.dart';
import 'package:six_minute_walk_test/core/sensors/location_service.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'gps_step_distance_estimator.dart';
import 'distance_estimator.dart';
import 'calibrated_step_distance_estimator.dart';
import 'adaptive_gps_step_distance_estimator.dart';
import 'estimator_comparison.dart';
import 'experimental_estimators.dart';
import 'kalman_gps_distance_estimator.dart';
import 'kalman_gps_step_distance_estimator.dart';
import 'walk_session.dart';

part 'walk_session_provider.g.dart';

final _log = appLogger('WalkSessionProvider');

/// Creates the database representation of the current walk session state.
WalkSessionRow? createWalkSessionRow(
  WalkSession session,
  WalkSessionState state,
) {
  final sessionId = state.sessionId;
  final startedAt = state.startedAt;
  final profileId = session.profileId;

  if (sessionId == null || startedAt == null || profileId == null) {
    return null;
  }

  return WalkSessionRow(
    id: sessionId,
    startedAt: startedAt,
    duration: session.walkDuration - state.remainingTime,
    distance: state.distance,
    phase: state.phase,
    profileId: profileId,
  );
}

/// Transforms [session.states] into a stream of [WalkSessionRow]s, skipping
/// emissions where none of the persisted fields have changed. So there we
/// prevent db writes on every sample
Stream<WalkSessionRow> deduplicatedSaves(WalkSession session) {
  WalkSessionRow? last;

  return session.states.expand((state) {
    final current = createWalkSessionRow(session, state);
    if (current == null) {
      if (state.sessionId != null && session.profileId == null) {
        _log.w('ProfileId is null. Cannot save Walk Session');
      }

      return [];
    }

    if (current == last) {
      return [];
    }

    last = current;
    return [current];
  });
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => LocationService();

// Kept alive for the whole app lifetime, so a running walk test survives
// navigating between screens.
@Riverpod(keepAlive: true)
WalkSession walkSession(Ref ref) {
  final session = WalkSession(
    sources: [GpsSource(locationService: ref.watch(locationServiceProvider))],
    // Phone steps support distance fallback when available; permission denial
    // or unsupported hardware does not prevent a GPS-only walk.
    optionalSources: [PedometerSource()],
    distanceEstimator: GpsStepDistanceEstimator(
      stepSourceId: PedometerSource.id,
    ),
    comparisonEstimators: [
      NamedDistanceEstimator('Plain GPS', GpsDistanceEstimator()),
      NamedDistanceEstimator(
        'Kalman GPS + steps',
        KalmanGpsStepDistanceEstimator(),
      ),
      NamedDistanceEstimator(
        'Adaptive GPS + steps',
        AdaptiveGpsStepDistanceEstimator(),
      ),
      NamedDistanceEstimator(
        'Calibrated steps',
        CalibratedStepDistanceEstimator(),
      ),
      NamedDistanceEstimator('Kalman GPS', KalmanGpsDistanceEstimator()),
      NamedDistanceEstimator(
        'Filtered GPS',
        FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
      ),
      NamedDistanceEstimator('Steps', StepDistanceEstimator(stepLength: 0.75)),
    ],
    sampleSink: ref.watch(sampleRepositoryProvider),
  );

  final walkSessionRepository = ref.watch(walkSessionRepositoryProvider);

  final subscription = deduplicatedSaves(
    session,
  ).listen(walkSessionRepository.saveSession);

  // A Dart timer can be paused while the app is backgrounded. Synchronizing on
  // resume ensures the visible countdown and the session phase immediately
  // reflect the wall-clock deadline.
  final lifecycleListener = AppLifecycleListener(
    onResume: session.synchronizeWithClock,
  );

  ref.onDispose(() {
    lifecycleListener.dispose();
    subscription.cancel();
    session.dispose();
  });

  return session;
}

@Riverpod(keepAlive: true)
Stream<WalkSessionState> walkSessionState(Ref ref) =>
    ref.watch(walkSessionProvider).states;
