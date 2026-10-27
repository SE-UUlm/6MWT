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
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import '../domain/walk_session_test.dart' show InitialSampleFakeSensorSource;

class _FixedProfileRepository extends ProfileRepository {
  _FixedProfileRepository(super.db, this.profile);
  final Profile profile;

  @override
  Future<Profile?> loadProfile(int profileId) async => profile;
}

void main() {
  testWidgets(
    'a long assessment category wraps instead of squeezing the card',
    (tester) async {
      // Narrow phone; the test font (Ahem) is wider than real text, hence 420.
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final session = WalkSession(
        sources: [InitialSampleFakeSensorSource([])],
        distanceEstimator: GpsStepDistanceEstimator(stepSourceId: 'steps'),
        now: () => tester.binding.clock.now(),
      );
      addTearDown(session.dispose);
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
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WalkScreen(profileId: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test starten'));
      await tester.pump(const Duration(seconds: 2));

      // The details are on the second page of the running view.
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      final title = find.text('Bewertung');
      expect(title, findsOneWidget);
      // The text column keeps a usable width instead of being squeezed to a few
      // letters per row (it was ~30 px wide when the chip took all the space).
      expect(tester.getSize(title).width, greaterThan(100));
      expect(
        find.text('Verminderte körperliche Leistungs\u00adfähigkeit'),
        findsOne,
      );
      expect(tester.takeException(), isNull);
      await session.abort();
      await tester.pump();
    },
  );
}
