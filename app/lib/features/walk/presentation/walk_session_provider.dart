import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/sensors/gps_source.dart';

import 'package:six_minute_walk_test/core/sensors/location_service.dart';
import '../domain/distance_estimator.dart';
import '../domain/walk_session.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

// Kept alive for the whole app lifetime, so a running walk test survives
// navigating between screens.
final walkSessionProvider = Provider<WalkSession>((ref) {
  final session = WalkSession(
    sources: [GpsSource(locationService: ref.watch(locationServiceProvider))],
    // Recorded when available, silently skipped when not (no wearable, no
    // permission, unsupported platform).
    optionalSources: [],
    distanceEstimator: GpsDistanceEstimator(),
    sampleSink: ref.watch(sampleRepositoryProvider),
  );

  ref.onDispose(session.dispose);

  return session;
});

final walkSessionStateProvider = StreamProvider<WalkSessionState>(
  (ref) => ref.watch(walkSessionProvider).states,
);
