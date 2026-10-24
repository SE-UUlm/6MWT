import 'dart:async';

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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import '../domain/walk_session_test.dart' show InitialSampleFakeSensorSource;

class PendingProfileRepository extends ProfileRepository {
  PendingProfileRepository(super.db, this.result);
  final Future<Profile?> result;

  @override
  Future<Profile?> loadProfile(int profileId) => result;
}

void main() {
  testWidgets(
    'waits for profile before starting with its estimated step length',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final pending = Completer<Profile?>();
      final estimator = GpsStepDistanceEstimator(stepSourceId: 'steps');
      final session = WalkSession(
        sources: [InitialSampleFakeSensorSource([])],
        distanceEstimator: estimator,
        now: () => tester.binding.clock.now(),
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walkSessionProvider.overrideWithValue(session),
            profileRepositoryProvider.overrideWithValue(
              PendingProfileRepository(db, pending.future),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: const [Locale('de'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const WalkScreen(profileId: 3),
          ),
        ),
      );
      final startButton = find.widgetWithText(ElevatedButton, 'Start Test');
      expect(tester.widget<ElevatedButton>(startButton).onPressed, isNull);
      expect(session.state.isRunning, isFalse);

      pending.complete(
        Profile(
          id: 3,
          timestamp: DateTime.utc(2026),
          height: 180,
          age: 30,
          weight: 70,
          gender: Gender.female,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(startButton).onPressed, isNotNull);
      await tester.tap(startButton);
      await tester.pump();
      expect(session.profileId, 3);
      expect(session.state.isRunning, isTrue);
      expect(estimator.stepLength, closeTo(0.7434, 1e-9));
      expect(estimator.hasLearnedStepLength, isFalse);
      await session.abort();
      await tester.pump();
    },
  );
}
