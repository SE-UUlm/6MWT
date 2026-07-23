import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/sensors/gps_source.dart';

import 'package:six_minute_walk_test/core/sensors/location_service.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'distance_estimator.dart';
import 'walk_session.dart';

part 'walk_session_provider.g.dart';

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
    sampleSink: ref.watch(sampleRepositoryProvider),
  );

  ref.onDispose(session.dispose);

  return session;
}

@Riverpod(keepAlive: true)
Stream<WalkSessionState> walkSessionState(Ref ref) =>
    ref.watch(walkSessionProvider).states;
