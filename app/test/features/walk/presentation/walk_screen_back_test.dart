import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/profile_repository.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_screen.dart';

import '../../../helpers/fake_sensors.dart';
import '../../../helpers/localized_app.dart';

class _FixedProfileRepository extends ProfileRepository {
  _FixedProfileRepository(super.db, this.profile);
  final Profile profile;

  @override
  Future<Profile?> loadProfile(int profileId) async => profile;
}

void main() {
  late AppDatabase db;
  late WalkSession session;

  Future<void> pumpWalkScreenOnTopOfHome(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    session = WalkSession(
      sources: [InitialSampleFakeSensorSource([])],
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
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WalkScreen()),
              ),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  testWidgets('back leaves the walk screen before the test starts', (
    tester,
  ) async {
    await pumpWalkScreenOnTopOfHome(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(WalkScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('back is blocked while the test is running', (tester) async {
    await pumpWalkScreenOnTopOfHome(tester);
    await tester.tap(find.text('Test starten'));
    await tester.pump(const Duration(seconds: 2));

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(WalkScreen), findsOneWidget);
    expect(
      find.text('Der Test läuft noch. Zum Beenden den Schieberegler nutzen.'),
      findsOneWidget,
    );
    await session.abort();
    await tester.pump();
  });
}
