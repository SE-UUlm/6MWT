import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sensors/location_service_provider.dart';
import '../domain/distance_estimator.dart';
import '../domain/walk_session.dart';

// Kept alive for the whole app lifetime, so a running test survives
// navigating between screens.
final walkSessionProvider = Provider<WalkSession>((ref) {
  final session = WalkSession(
    locationService: ref.watch(locationServiceProvider),
    distanceEstimator: GpsDistanceEstimator(),
  );

  ref.onDispose(session.dispose);

  return session;
});

final walkSessionStateProvider = StreamProvider<WalkSessionState>(
  (ref) => ref.watch(walkSessionProvider).states,
);
