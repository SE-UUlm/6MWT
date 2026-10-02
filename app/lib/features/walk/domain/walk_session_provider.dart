import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/sensors/gps_source.dart';
import 'package:six_minute_walk_test/core/sensors/location_service.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'distance_estimator.dart';
import 'estimator_comparison.dart';
import 'experimental_estimators.dart';
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
    // Recorded when available, silently skipped when not (no wearable, no
    // permission, unsupported platform).
    optionalSources: [PedometerSource()],
    distanceEstimator: GpsDistanceEstimator(),
    comparisonEstimators: [
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

  ref.onDispose(() {
    subscription.cancel();
    session.dispose();
  });

  return session;
}

@Riverpod(keepAlive: true)
Stream<WalkSessionState> walkSessionState(Ref ref) =>
    ref.watch(walkSessionProvider).states;
