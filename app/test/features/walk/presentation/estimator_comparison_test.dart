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
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimator_comparison.dart';
import 'package:six_minute_walk_test/features/walk/domain/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/estimator_comparison_card.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';

import '../domain/walk_session_test.dart' show InitialSampleFakeSensorSource;

final profile = Profile(
  id: 1,
  timestamp: DateTime.utc(2026),
  height: 170,
  age: 30,
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
    'live comparison survives reset and result navigation; history hides it',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final source = InitialSampleFakeSensorSource([steps(100)]);
      final session = WalkSession(
        sources: [source],
        distanceEstimator: GpsDistanceEstimator(),
        comparisonEstimators: [
          NamedDistanceEstimator(
            'Steps',
            StepDistanceEstimator(stepLength: 0.75),
          ),
        ],
        walkDuration: const Duration(seconds: 5),
        now: () => tester.binding.clock.now(),
      );
      router.go('/walk', extra: 1);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walkSessionProvider.overrideWithValue(session),
            profileRepositoryProvider.overrideWithValue(
              TestProfileRepository(db),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
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
      expect(
        tester.getTopLeft(find.text('Distance comparison')).dy,
        greaterThan(tester.getTopLeft(find.text('Duration')).dy),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(session.state.phase, WalkPhase.idle);
      expect(session.state.comparisons, isEmpty);
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
        lessThan(tester.getTopLeft(find.text('Your Profile')).dy),
      );
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      router.go(
        '/result',
        extra: WalkSessionWithProfile(
          session: result.session,
          profile: profile,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byType(EstimatorComparisonCard), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await session.dispose();
      router.go('/');
    },
  );

  testWidgets('comparison card shows diagnostics and errors without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
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
                  name: 'Broken estimator',
                  distance: 123,
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
    expect(tester.takeException(), isNull);
  });
}
