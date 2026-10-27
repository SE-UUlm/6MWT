import 'package:six_minute_walk_test/core/data/sample_repository.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/app/router.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/profile_repository.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_confidence.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimator_comparison.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/estimator_comparison_card.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';

import '../domain/walk_session_test.dart' show InitialSampleFakeSensorSource;
import '../../../helpers/localized_app.dart';

final profile = Profile(
  id: 1,
  timestamp: DateTime.utc(2026),
  height: 170,
  age: 30,
  weight: 70,
  gender: Gender.other,
);

class TestProfileRepository extends ProfileRepository {
  TestProfileRepository(super.db);

  @override
  Future<Profile?> loadProfile(int profileId) async => profile;
}

SensorSample steps(double count) => SensorSample(
  timestamp: DateTime.utc(2026),
  type: SampleType.steps,
  sourceId: 'steps',
  values: {StepKeys.cumulativeSteps: count},
);

void main() {
  testWidgets(
    'live comparison survives reset and is computed live in result screen and history',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: const Value(1),
              height: 170,
              age: 30,
              weight: 70,
              gender: Gender.other,
            ),
          );
      final source = InitialSampleFakeSensorSource([steps(100)]);
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        comparisonEstimators: [StepDistanceEstimator(stepLength: 0.75)],
        sampleSink: SampleRepository(db),
        walkDuration: const Duration(seconds: 5),
        now: () => tester.binding.clock.now(),
      );
      final sessionSub = deduplicatedSaves(
        session,
      ).listen(WalkSessionRepository(db).saveSession);
      addTearDown(sessionSub.cancel);
      router.go('/walk', extra: 1);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            walkSessionProvider.overrideWithValue(session),
            profileRepositoryProvider.overrideWithValue(
              TestProfileRepository(db),
            ),
          ],
          child: localizedRouterApp(router: router),
        ),
      );
      await tester.pumpAndSettle();
      await session.start();
      await tester.pump();
      await tester.drag(find.byType(PageView), const Offset(-1000, 0));
      await tester.pumpAndSettle();
      expect(find.byType(EstimatorComparisonCard), findsOneWidget);
      source.controller.add(steps(102));
      await tester.pump();
      await tester.pump();
      expect(find.text('1.5 m'), findsOneWidget);
      // The primary estimator is listed first, above the comparisons.
      expect(
        tester.getTopLeft(find.text('Main (Plain GPS)')).dy,
        lessThan(tester.getTopLeft(find.text('Steps')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Distance comparison')).dy,
        greaterThan(tester.getTopLeft(find.text('Duration')).dy),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(session.state.phase, WalkPhase.idle);
      expect(session.state.comparisons, isEmpty);
      expect(find.byType(EstimatorComparisonCard), findsOneWidget);
      expect(find.text('1.5 m'), findsOneWidget);
      final comparisonY = tester
          .getTopLeft(find.text('Distance comparison'))
          .dy;
      expect(
        comparisonY,
        greaterThan(tester.getTopLeft(find.text('Test Details')).dy),
      );
      expect(
        comparisonY,
        greaterThan(tester.getTopLeft(find.text('Your Profile')).dy),
      );
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      router.go(
        '/result',
        extra: WalkSessionWithProfile(
          session: result.session,
          profile: profile,
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byType(EstimatorComparisonCard), findsOneWidget);
      expect(find.text('1.5 m'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await session.dispose();
      router.go('/');
    },
  );

  testWidgets('result screen with empty samples hides comparison card', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final emptySession = WalkSessionWithProfile(
      session: WalkSessionRow(
        id: 'no-samples-session',
        startedAt: DateTime.utc(2026),
        duration: const Duration(minutes: 6),
        distance: 100,
        phase: WalkPhase.finished,
        profileId: 1,
      ),
      profile: profile,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: localizedApp(
          locale: const Locale('en'),
          home: ResultScreen(session: emptySession),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byType(EstimatorComparisonCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comparison card shows diagnostics and errors without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: EstimatorComparisonCard(
              comparisons: [
                EstimatorComparison(
                  name: 'Steps',
                  distance: 0,
                  additionalInfo: {'Step source': 'No step samples'},
                ),
                EstimatorComparison(
                  name: 'Kalman GPS',
                  distance: 400,
                  confidence: const DistanceConfidence(0.8),
                ),
                EstimatorComparison(
                  name: 'Broken estimator',
                  distance: 123,
                  confidence: const DistanceConfidence(0.9),
                  error: 'Sensor calculation failed',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Step source: No step samples'), findsOneWidget);
    expect(
      find.text('Estimator unavailable: Sensor calculation failed'),
      findsOneWidget,
    );
    expect(find.text('123.0 m'), findsNothing);
    // Only estimators that assess their distance and did not fail show one.
    expect(find.text('Confidence: High (80 %)'), findsOneWidget);
    expect(find.textContaining('Confidence:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ResultScreen live calculates and displays all estimators including main estimator and its additional info',
    (tester) async {
      final recordedProfile = profile.copyWith(
        height: 180,
        gender: Gender.female,
      );
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: const Value(1),
              height: recordedProfile.height,
              age: 30,
              weight: 70,
              gender: recordedProfile.gender,
            ),
          );

      const sessionId = 'session-live-test';
      final t1 = DateTime.utc(2026, 7, 1, 12, 0, 0);
      final t2 = DateTime.utc(2026, 7, 1, 12, 0, 1);
      final t3 = DateTime.utc(2026, 7, 1, 12, 0, 2);

      await db
          .into(db.walkSessions)
          .insert(
            WalkSessionsCompanion.insert(
              id: sessionId,
              startedAt: t1,
              duration: const Duration(minutes: 6),
              distance: 55.6,
              phase: WalkPhase.finished,
              profileId: 1,
            ),
          );

      final sampleRepo = SampleRepository(db);

      sampleRepo.addSample(
        sessionId,
        SensorSample(
          timestamp: t1,
          type: SampleType.position,
          sourceId: 'gps',
          values: {
            PositionKeys.latitude: 48.0,
            PositionKeys.longitude: 10.0,
            PositionKeys.accuracy: 5.0,
            PositionKeys.speed: 1.0,
          },
        ),
      );
      sampleRepo.addSample(
        sessionId,
        SensorSample(
          timestamp: t2,
          type: SampleType.position,
          sourceId: 'gps',
          values: {
            PositionKeys.latitude: 48.0005,
            PositionKeys.longitude: 10.0,
            PositionKeys.accuracy: 5.0,
            PositionKeys.speed: 1.0,
          },
        ),
      );
      sampleRepo.addSample(
        sessionId,
        SensorSample(
          timestamp: t3,
          type: SampleType.steps,
          sourceId: PedometerSource.id,
          values: {StepKeys.cumulativeSteps: 25.0},
        ),
      );
      sampleRepo.addSample(
        sessionId,
        SensorSample(
          timestamp: t3.add(const Duration(seconds: 10)),
          type: SampleType.steps,
          sourceId: PedometerSource.id,
          values: {StepKeys.cumulativeSteps: 35.0},
        ),
      );
      await sampleRepo.flush();

      final session = WalkSessionWithProfile(
        session: WalkSessionRow(
          id: sessionId,
          startedAt: t1,
          duration: const Duration(minutes: 6),
          distance: 55.6,
          phase: WalkPhase.finished,
          profileId: 1,
        ),
        profile: recordedProfile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: localizedApp(
            locale: const Locale('en'),
            home: ResultScreen(session: session),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.byType(EstimatorComparisonCard), findsOneWidget);
      expect(find.text('Main (GPS + steps)'), findsOneWidget);
      expect(find.text('Plain GPS'), findsOneWidget);
      expect(find.text('Kalman GPS + steps'), findsOneWidget);
      expect(find.text('Adaptive GPS + steps'), findsOneWidget);
      expect(find.text('Calibrated steps'), findsOneWidget);
      expect(find.text('Kalman GPS'), findsOneWidget);
      expect(find.text('Filtered GPS'), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);

      final card = tester.widget<EstimatorComparisonCard>(
        find.byType(EstimatorComparisonCard),
      );
      expect(card.comparisons.first.distance, closeTo(7.434, 1e-6));
      expect(card.comparisons.first.additionalInfo['Step length'], '0.743 m');

      // Verify additional info from main estimator is displayed
      expect(find.text('GPS fallback timeout: 5.0 s'), findsOneWidget);
      expect(find.text('Step source: pedometer'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
