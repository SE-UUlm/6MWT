import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/sensors/gps_source.dart';
import 'package:six_minute_walk_test/core/sensors/providers.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'estimators/gps_step_distance_estimator.dart';
import 'estimators/distance_estimator.dart';
import 'estimators/calibrated_step_distance_estimator.dart';
import 'estimators/adaptive_gps_step_distance_estimator.dart';
import 'estimator_comparison.dart';
import 'estimators/experimental_estimators.dart';
import 'estimators/kalman_gps_distance_estimator.dart';
import 'estimators/kalman_gps_step_distance_estimator.dart';
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
    distanceConfidence: state.confidence?.score,
    phase: state.phase,
    profileId: profileId,
  );
}

/// Maps session states to database rows, skipping consecutive identical rows.
/// A changed distance or duration still produces a row for persistence.
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

/// Creates the primary distance estimator used to calculate the session distance.
NamedDistanceEstimator createPrimaryDistanceEstimator() =>
    NamedDistanceEstimator(
      'Main (GPS + steps)',
      GpsStepDistanceEstimator(stepSourceId: PedometerSource.id),
    );

/// Creates the secondary distance estimators used for comparisons during the walk.
List<NamedDistanceEstimator> createComparisonEstimators() => [
  NamedDistanceEstimator('Plain GPS', GpsDistanceEstimator()),
  NamedDistanceEstimator(
    'Kalman GPS + steps',
    KalmanGpsStepDistanceEstimator(),
  ),
  NamedDistanceEstimator(
    'Adaptive GPS + steps',
    AdaptiveGpsStepDistanceEstimator(),
  ),
  NamedDistanceEstimator('Calibrated steps', CalibratedStepDistanceEstimator()),
  NamedDistanceEstimator('Kalman GPS', KalmanGpsDistanceEstimator()),
  NamedDistanceEstimator(
    'Filtered GPS',
    FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
  ),
  NamedDistanceEstimator('Steps', StepDistanceEstimator(stepLength: 0.75)),
];

/// Creates all distance estimators, including the primary estimator first.
List<NamedDistanceEstimator> createAllDistanceEstimators() => [
  createPrimaryDistanceEstimator(),
  ...createComparisonEstimators(),
];

// Kept alive for the whole app lifetime, so a running walk test survives
// navigating between screens.
@Riverpod(keepAlive: true)
WalkSession walkSession(Ref ref) {
  final primaryEstimator = createPrimaryDistanceEstimator();
  final session = WalkSession(
    sources: [GpsSource(locationService: ref.watch(locationServiceProvider))],
    // Phone steps support distance fallback when available; permission denial
    // or unsupported hardware does not prevent a GPS-only walk.
    optionalSources: [PedometerSource()],
    distanceEstimator: primaryEstimator.estimator,
    distanceEstimatorName: primaryEstimator.name,
    comparisonEstimators: createComparisonEstimators(),
    sampleSink: ref.watch(sampleRepositoryProvider),
  );

  final walkSessionRepository = ref.watch(walkSessionRepositoryProvider);

  final subscription = deduplicatedSaves(session).listen(
    walkSessionRepository.saveSession,
    onError: (Object error, StackTrace stack) =>
        _log.e('Cannot save walk session', error: error, stackTrace: stack),
  );

  ref.onDispose(() {
    subscription.cancel();
    session.dispose();
  });

  return session;
}

@Riverpod(keepAlive: true)
Stream<WalkSessionState> walkSessionState(Ref ref) =>
    ref.watch(walkSessionProvider).states;

/// Samples and profile values passed to the background calculation.
class EstimatorComparisonInput {
  const EstimatorComparisonInput({
    required this.samples,
    this.heightCm,
    this.gender,
  });

  final List<SensorSample> samples;
  final num? heightCm;
  final String? gender;
}

List<EstimatorComparison> computeEstimatorComparisons(
  EstimatorComparisonInput input,
) {
  final samples = input.samples;
  if (samples.isEmpty) {
    return const [];
  }

  final estimators = createAllDistanceEstimators();

  final comparisons = <EstimatorComparison>[];

  for (final named in estimators) {
    try {
      named.estimator.configureProfile(
        heightCm: input.heightCm,
        gender: input.gender,
      );
      named.estimator.reset();

      for (final sample in samples) {
        named.estimator.addSample(sample);
      }

      final distance = named.estimator.totalDistance;
      if (!distance.isFinite || distance < 0) {
        throw StateError('Invalid calculated distance: $distance');
      }

      comparisons.add(
        EstimatorComparison(
          name: named.name,
          distance: distance,
          additionalInfo: named.estimator.additionalInfo,
          confidence: named.estimator.confidence,
        ),
      );
    } catch (e) {
      comparisons.add(
        EstimatorComparison(name: named.name, distance: 0, error: e.toString()),
      );
    }
  }

  return comparisons;
}

@riverpod
Future<List<EstimatorComparison>> sessionEstimatorComparisons(
  Ref ref,
  String sessionId, {
  num? heightCm,
  String? gender,
}) async {
  try {
    final sampleRepository = ref.watch(sampleRepositoryProvider);
    final samples = await sampleRepository.loadSessionSamples(sessionId);
    if (samples.isEmpty) {
      return const [];
    }
    final stopwatch = Stopwatch()..start();

    final result = await compute(
      computeEstimatorComparisons,
      EstimatorComparisonInput(
        samples: samples,
        heightCm: heightCm,
        gender: gender,
      ),
    ); // Run in background

    stopwatch.stop();
    _log.t(
      'Calculated ${result.length} estimator comparisons for $sessionId '
      'in ${stopwatch.elapsedMilliseconds} ms (${samples.length} samples)',
    );
    return result;
  } catch (error, stackTrace) {
    _log.w(
      'Failed to compute estimator comparisons for $sessionId',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
