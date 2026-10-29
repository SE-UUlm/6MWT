import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/profile_repository.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_screen.dart';

import '../../../helpers/fake_sensors.dart';
import '../../../helpers/localized_app.dart';
import '../../../helpers/logs.dart';

class _FixedProfileRepository extends ProfileRepository {
  _FixedProfileRepository(super.db, this.profile);
  final Profile profile;

  @override
  Future<Profile?> loadProfile(int profileId) async => profile;
}

/// Fails to start like a GPS source without location access, until allowed.
class _LocationSource extends FakeSensorSource {
  bool allowed = false;

  @override
  Future<void> start() async {
    if (!allowed) {
      throw const SensorUnavailableException(
        'Location permission denied or GPS disabled',
        issue: SensorIssue.locationUnavailable,
      );
    }
    await super.start();
  }
}

void main() {
  testWidgets('without location access the test shows a large error', (
    tester,
  ) async {
    silenceLogs();
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final source = _LocationSource();
    final session = WalkSession(
      sources: [source],
      distanceEstimator: GpsStepDistanceEstimator(stepSourceId: 'steps'),
      now: () => tester.binding.clock.now(),
    );
    addTearDown(session.dispose);
    session.setProfile(id: 3, heightCm: 180, gender: Gender.female.name);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walkSessionProvider.overrideWithValue(session),
          profileRepositoryProvider.overrideWithValue(
            _FixedProfileRepository(
              db,
              Profile(
                id: 3,
                timestamp: DateTime.utc(2026),
                height: 180,
                age: 30,
                weight: 70,
                gender: Gender.female,
              ),
            ),
          ),
        ],
        child: localizedApp(
          locale: const Locale('de'),
          home: const WalkScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test starten'));
    await tester.pumpAndSettle();
    expect(session.state.isRunning, isFalse);
    expect(find.byKey(const ValueKey('location-error')), findsOneWidget);
    expect(find.text('Standortzugriff erforderlich'), findsOneWidget);

    // Once access is allowed, starting again by hand runs the test.
    source.allowed = true;
    await tester.tap(find.text('Test starten'));
    await tester.pump();
    expect(session.state.isRunning, isTrue);
    expect(find.byKey(const ValueKey('location-error')), findsNothing);
    await session.abort();
    await tester.pump();
  });
}
