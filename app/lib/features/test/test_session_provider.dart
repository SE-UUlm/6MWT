import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/distance_estimator.dart';
import '../../core/domain/test_session.dart';
import '../../core/sensors/location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

// Kept alive for the whole app lifetime, so a running test survives
// navigating between screens.
final testSessionProvider = Provider<TestSession>((ref) {
  final session = TestSession(
    locationService: ref.watch(locationServiceProvider),
    distanceEstimator: GpsDistanceEstimator(),
  );

  ref.onDispose(session.dispose);

  return session;
});

final testSessionStateProvider = StreamProvider<TestSessionState>(
  (ref) => ref.watch(testSessionProvider).states,
);
