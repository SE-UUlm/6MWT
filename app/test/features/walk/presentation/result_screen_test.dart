import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimator_comparison.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_confidence.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';

import '../../../helpers/localized_app.dart';

void main() {
  for (final (gender, label, weight, weightLabel) in [
    (Gender.male, 'Männlich', 75.0, '75 kg'),
    (Gender.female, 'Weiblich', 62.5, '62,5 kg'),
    (Gender.other, 'Divers/Keine Angabe', 0.0, '0 kg'),
  ]) {
    testWidgets('shows $label and $weightLabel in profile details', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: localizedApp(
            locale: const Locale('de'),
            home: ResultScreen(
              session: WalkSessionWithProfile(
                session: WalkSessionRow(
                  id: 'test',
                  startedAt: DateTime.utc(2026),
                  duration: const Duration(minutes: 6),
                  distance: 450,
                  phase: WalkPhase.finished,
                  profileId: 1,
                ),
                profile: Profile(
                  id: 1,
                  timestamp: DateTime.utc(2026),
                  height: 170,
                  age: 30,
                  gender: gender,
                  weight: weight,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text(weightLabel));
      await tester.pumpAndSettle();
      expect(find.text(weightLabel), findsOneWidget);
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  final testSession = WalkSessionWithProfile(
    session: WalkSessionRow(
      id: 'state-test-session',
      startedAt: DateTime.utc(2026),
      duration: const Duration(minutes: 6),
      distance: 450,
      phase: WalkPhase.finished,
      profileId: 1,
    ),
    profile: Profile(
      id: 1,
      timestamp: DateTime.utc(2026),
      height: 170,
      age: 30,
      gender: Gender.male,
      weight: 75.0,
    ),
  );

  testWidgets('shows loading spinner while comparisons are calculating', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionEstimatorComparisonsProvider(
            'state-test-session',
            heightCm: testSession.profile.height,
            gender: testSession.profile.gender.name,
          ).overrideWith(
            (ref) => Completer<List<EstimatorComparison>>().future,
          ),
        ],
        child: localizedApp(
          locale: const Locale('en'),
          home: ResultScreen(session: testSession),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Calculating distance comparisons...'), findsOneWidget);
  });

  testWidgets('shows no confidence for sessions without a stored value', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionEstimatorComparisonsProvider(
            'state-test-session',
            heightCm: testSession.profile.height,
            gender: testSession.profile.gender.name,
          ).overrideWith(
            (ref) async => [
              EstimatorComparison(
                name: 'Main',
                distance: 450,
                confidence: const DistanceConfidence(0.62),
              ),
              EstimatorComparison(
                name: 'Other',
                distance: 400,
                confidence: const DistanceConfidence(0.95),
              ),
            ],
          ),
        ],
        child: localizedApp(
          locale: const Locale('en'),
          home: ResultScreen(session: testSession),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Distance confidence'), findsOneWidget);
    // The replayed value appears only in the comparison card.
    expect(find.text('Medium (62 %)'), findsNothing);
    expect(find.text('Confidence: Medium (62 %)'), findsOneWidget);
    final confidenceRow = find.ancestor(
      of: find.text('Distance confidence'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: confidenceRow, matching: find.text('—')),
      findsOneWidget,
    );
  });

  testWidgets('shows the stored confidence, not the replayed one', (
    tester,
  ) async {
    final stored = WalkSessionWithProfile(
      session: testSession.session.copyWith(
        distanceConfidence: const Value(0.81),
      ),
      profile: testSession.profile,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionEstimatorComparisonsProvider(
            'state-test-session',
            heightCm: testSession.profile.height,
            gender: testSession.profile.gender.name,
          ).overrideWith(
            (ref) async => [
              EstimatorComparison(
                name: 'Main',
                distance: 450,
                confidence: const DistanceConfidence(0.2),
              ),
            ],
          ),
        ],
        child: localizedApp(
          locale: const Locale('en'),
          home: ResultScreen(session: stored),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('High (81 %)'), findsOneWidget);
  });

  for (final (phase, percent, marker, explanation) in [
    (
      WalkPhase.finished,
      findsNothing,
      findsOneWidget,
      'Your performance is based on your age, height and walking distance.',
    ),
    (
      WalkPhase.aborted,
      findsOneWidget,
      findsNothing,
      'No assessment is possible because the test was stopped early.',
    ),
    (
      WalkPhase.running,
      findsOneWidget,
      findsNothing,
      'No assessment is possible because the test was stopped early.',
    ),
  ]) {
    testWidgets('performance card for a ${phase.name} test', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionEstimatorComparisonsProvider(
              'state-test-session',
              heightCm: testSession.profile.height,
              gender: testSession.profile.gender.name,
            ).overrideWith((ref) async => const []),
          ],
          child: localizedApp(
            locale: const Locale('en'),
            home: ResultScreen(
              session: WalkSessionWithProfile(
                session: testSession.session.copyWith(phase: phase),
                profile: testSession.profile,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The percentage placeholder replaces the value, never shows 0 %.
      final percentage = find.byWidgetPredicate(
        (w) => w is Text && w.style?.fontSize == 46 && w.data == '—',
      );
      expect(percentage, percent);
      expect(find.text('0%'), findsNothing);
      expect(find.byKey(const ValueKey('performance-marker')), marker);
      expect(find.text(explanation), findsOneWidget);
    });
  }

  for (final (phase, confidence, warning) in [
    (WalkPhase.finished, 0.3, findsOneWidget),
    (WalkPhase.finished, 0.6, findsNothing),
    (WalkPhase.finished, null, findsNothing),
    // Without an assessment there is nothing to warn about.
    (WalkPhase.aborted, 0.3, findsNothing),
  ]) {
    testWidgets(
      'low confidence warning for a ${phase.name} test with confidence '
      '$confidence',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionEstimatorComparisonsProvider(
                'state-test-session',
                heightCm: testSession.profile.height,
                gender: testSession.profile.gender.name,
              ).overrideWith((ref) async => const []),
            ],
            child: localizedApp(
              locale: const Locale('en'),
              home: ResultScreen(
                session: WalkSessionWithProfile(
                  session: testSession.session.copyWith(
                    phase: phase,
                    distanceConfidence: Value(confidence),
                  ),
                  profile: testSession.profile,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('low-confidence-warning')), warning);
      },
    );
  }

  testWidgets('shows error card on calculation failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionEstimatorComparisonsProvider(
            'state-test-session',
            heightCm: testSession.profile.height,
            gender: testSession.profile.gender.name,
          ).overrideWith((ref) {
            throw StateError('Simulated calculation error');
          }),
        ],
        child: localizedApp(
          locale: const Locale('en'),
          home: ResultScreen(session: testSession),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Could not calculate distance comparisons.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
  });

  group('Delete session functionality', () {
    testWidgets('shows delete session button at the bottom', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: localizedApp(
            locale: const Locale('en'),
            home: ResultScreen(session: testSession),
          ),
        ),
      );

      final deleteButtonFinder = find.widgetWithText(
        OutlinedButton,
        'Delete walk test',
      );
      await tester.ensureVisible(deleteButtonFinder);
      await tester.pumpAndSettle();
      expect(deleteButtonFinder, findsOneWidget);
    });

    testWidgets('cancelling dialog does not delete session', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WalkSessionRepository(db);

      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: const Value(1),
              height: 170,
              age: 30,
              weight: 70,
              gender: Gender.male,
            ),
          );
      await repo.saveSession(testSession.session);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            walkSessionRepositoryProvider.overrideWithValue(repo),
          ],
          child: localizedApp(
            locale: const Locale('en'),
            home: ResultScreen(session: testSession),
          ),
        ),
      );

      final deleteButtonFinder = find.widgetWithText(
        OutlinedButton,
        'Delete walk test',
      );
      await tester.ensureVisible(deleteButtonFinder);
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete walk test?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      // Session must still exist in DB
      final sessionInDb = await (db.select(
        db.walkSessions,
      )..where((s) => s.id.equals(testSession.session.id))).getSingleOrNull();
      expect(sessionInDb, isNotNull);
    });

    testWidgets(
      'confirming delete calls deleteSession and removes session from DB',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = WalkSessionRepository(db);

        await db
            .into(db.profiles)
            .insert(
              ProfilesCompanion.insert(
                id: const Value(1),
                height: 170,
                age: 30,
                weight: 70,
                gender: Gender.male,
              ),
            );
        await repo.saveSession(testSession.session);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              walkSessionRepositoryProvider.overrideWithValue(repo),
            ],
            child: localizedApp(
              locale: const Locale('en'),
              home: ResultScreen(session: testSession),
            ),
          ),
        );

        final deleteButtonFinder = find.widgetWithText(
          OutlinedButton,
          'Delete walk test',
        );
        await tester.ensureVisible(deleteButtonFinder);
        await tester.tap(deleteButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Walk test deleted'), findsOneWidget);

        final sessionInDb = await (db.select(
          db.walkSessions,
        )..where((s) => s.id.equals(testSession.session.id))).getSingleOrNull();
        expect(sessionInDb, isNull);
      },
    );

    testWidgets('prevents deleting session if it is currently running', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WalkSessionRepository(db);

      final runningSession = WalkSession(
        sources: [],
        distanceEstimator: GpsDistanceEstimator(),
      );
      // Put session into running state with testSession.session.id
      runningSession.profileId = 1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            walkSessionRepositoryProvider.overrideWithValue(repo),
            walkSessionProvider.overrideWithValue(runningSession),
          ],
          child: localizedApp(
            locale: const Locale('en'),
            home: ResultScreen(session: testSession),
          ),
        ),
      );

      // Start the session so isRunning is true
      await runningSession.start();

      // Now create a result screen with matching sessionId
      final activeResultSession = WalkSessionWithProfile(
        session: WalkSessionRow(
          id: runningSession.state.sessionId!,
          startedAt: DateTime.utc(2026),
          duration: const Duration(minutes: 6),
          distance: 100,
          phase: WalkPhase.running,
          profileId: 1,
        ),
        profile: testSession.profile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            walkSessionRepositoryProvider.overrideWithValue(repo),
            walkSessionProvider.overrideWithValue(runningSession),
          ],
          child: localizedApp(
            locale: const Locale('en'),
            home: ResultScreen(session: activeResultSession),
          ),
        ),
      );

      final deleteButtonFinder = find.widgetWithText(
        OutlinedButton,
        'Delete walk test',
      );
      await tester.ensureVisible(deleteButtonFinder);
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();

      // Dialog must NOT be shown, instead error SnackBar
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text('An active walk test cannot be deleted.'),
        findsOneWidget,
      );

      await runningSession.dispose();
    });
  });
}
