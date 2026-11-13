// test/features/flow_tests/gui_flow_test.dart
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:six_minute_walk_test/app/notification_providers.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart'; // WalkSessionWithProfile
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';
import 'package:six_minute_walk_test/features/home/home_screen.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/information_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/quick_guide_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import '../../helpers/fake_notifications.dart';

/// Sensor that never delivers data; it only replaces the GPS plugin.
class FakeSensorSource implements SensorSource {
  final _controller = StreamController<SensorSample>.broadcast();

  @override
  String get sourceId => 'fake';

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<List<SensorSample>> getInitialSamples() async => const [];
}

GoRouter _testRouter() => GoRouter(
  initialLocation: '/', // start = HomeScreen
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/quick-guide', builder: (_, __) => const QuickGuideScreen()),
    GoRoute(path: '/walk', builder: (_, __) => const WalkScreen()),
    GoRoute(
      path: '/result',
      builder: (_, state) =>
          ResultScreen(session: state.extra as WalkSessionWithProfile),
    ),
  ],
);

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(Scaffold).first))!;

/// pumpAndSettle would hang on the running walk timer, so pump manually.
Future<void> _pump(WidgetTester t, [int ms = 600]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

/// Lets real async work finish. The test body runs in a FakeAsync zone, where
/// real I/O would otherwise never complete.
Future<void> _realWait(WidgetTester t, [int ms = 300]) async {
  await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await _pump(t);
}

/// Scrolls the target into view before tapping, so the tap does not miss.
Future<void> _tapVisible(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
}

void main() {
  testWidgets('GUI flow: Home -> Information -> Guide -> Walk -> Result', (
    tester,
  ) async {
    // 400 x 1333 logical pixels: tall enough that little scrolling is needed.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    // Test font "Ahem" is much wider than the real font, so RenderFlex overflows
    // are an artifact of the test environment. All other errors still fail the test.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    // In-memory database instead of the real file (no path_provider needed).
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Notification plugin replaced by a fake that records its calls.
    final notifications = FakeNotificationService();

    // Real WalkSession, but with the fake sensor instead of GPS/pedometer.
    final session = WalkSession(
      sources: [FakeSensorSource()],
      distanceEstimator: createPrimaryDistanceEstimator(),
      notificationSender: notifications,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          walkSessionProvider.overrideWithValue(session),
          localNotificationServiceProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp.router(
          routerConfig: _testRouter(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);

    // ---------- 1) Home ----------
    expect(find.text(l10n.appTitle), findsOneWidget);
    expect(find.text(l10n.appSubTitle), findsOneWidget);
    expect(find.text(l10n.home_walk), findsOneWidget);
    expect(find.text(l10n.home_performance), findsOneWidget);
    expect(find.text(l10n.home_progress), findsOneWidget);
    expect(find.text(l10n.home_result), findsOneWidget);
    expect(find.text(l10n.home_instruction), findsOneWidget);
    expect(find.byTooltip(l10n.aboutTitle), findsOneWidget);
    expect(find.text(l10n.startTest), findsOneWidget);

    await _tapVisible(tester, find.text(l10n.startTest));
    await tester.pumpAndSettle();

    // ---------- 2) Information input ----------
    expect(find.text(l10n.profile_title), findsOneWidget);
    expect(find.text(l10n.profile_text), findsOneWidget);
    expect(
      find.byType(TextField),
      findsNWidgets(4),
    ); // name, age, height, weight
    expect(find.text(l10n.genderMale), findsOneWidget);
    expect(find.text(l10n.genderFemale), findsOneWidget);
    expect(find.text(l10n.genderOther), findsOneWidget);
    expect(find.text(l10n.profile_footer), findsOneWidget);
    expect(find.text(l10n.continueButton), findsOneWidget);

    // Fill only so that the continue button leads to the next screen.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Test');
    await tester.enterText(fields.at(1), '30');
    await tester.enterText(fields.at(2), '175');
    await tester.enterText(fields.at(3), '70');
    await _tapVisible(tester, find.text(l10n.genderMale));
    await tester.pump();
    await _tapVisible(tester, find.text(l10n.continueButton));
    await _realWait(tester); // ensureProfile writes to the database

    // ---------- 3) Quick guide ----------
    expect(find.text(l10n.quickGuide_title), findsOneWidget);
    expect(find.text(l10n.quickGuide_step_outdoor), findsOneWidget);
    expect(find.text(l10n.quickGuide_step_pocket), findsOneWidget);
    expect(find.text(l10n.quickGuide_step_walk), findsOneWidget);
    expect(find.text(l10n.quickGuide_step_end), findsOneWidget);
    expect(find.text(l10n.quickGuide_more_info), findsOneWidget);
    expect(find.text(l10n.quickGuide_disclaimer), findsOneWidget);

    await _tapVisible(tester, find.text(l10n.continueButton));
    await _realWait(tester); // WalkScreen loads the profile

    // Continuing asks for notification permission (end-of-test signal); the
    // walk screen checks it again and shows no hint because it was granted.
    expect(notifications.permissionRequests, 1);
    expect(notifications.checks, greaterThanOrEqualTo(2));
    expect(find.text(l10n.notificationsDisabledWarningAndroid), findsNothing);

    // ---------- 4) Walk: simple view ----------
    expect(find.text(l10n.startTest), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    // Walk: detailed view (swipe)
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await _pump(tester);
    expect(find.text(l10n.walkPleaseGoFar), findsOneWidget);
    expect(find.text(l10n.walk_idstance), findsOneWidget);
    expect(find.text(l10n.walk_status), findsOneWidget);
    expect(find.text(l10n.walk_assessment), findsOneWidget);
    expect(find.text(l10n.walk_position), findsOneWidget);
    expect(find.text(l10n.walk_duration), findsOneWidget);
    expect(find.text(l10n.walk_profile), findsOneWidget);
    expect(find.text(l10n.resultDisclaimer), findsOneWidget);

    // Back to simple view, start, check stop slider
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await _pump(tester);
    await tester.tap(find.text(l10n.startTest));
    await _realWait(tester);
    expect(find.text(l10n.walkSlideToStop), findsOneWidget);

    // Stop via slider -> navigates to result
    await tester.drag(
      find.byIcon(Icons.chevron_right_rounded),
      const Offset(600, 0),
    );
    await _realWait(tester, 500); // abort + navigation

    // Starting removed any previous end-of-test notification; stopping early
    // must not signal the end of the test.
    expect(notifications.cancelledIds, hasLength(1));
    expect(notifications.shownTitles, isEmpty);

    // ---------- 5) Result ----------
    expect(find.text(l10n.resultTitle), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.text(l10n.resultIntro), findsOneWidget);
    expect(find.text(l10n.resultPerformance), findsOneWidget);
    expect(find.text(l10n.resultExpectedDistance), findsOneWidget);
    expect(find.text(l10n.resultTestDetails), findsOneWidget);
    expect(find.text(l10n.resultDistanceWalked), findsOneWidget);
    expect(find.text(l10n.resultDistanceConfidence), findsOneWidget);
    expect(find.text(l10n.resultTestDuration), findsOneWidget);
    expect(find.text(l10n.resultTestStatus), findsOneWidget);
    expect(find.text(l10n.resultStoppedEarly), findsOneWidget);
    expect(find.text(l10n.resultYourProfile), findsOneWidget);
    expect(find.text(l10n.resultName), findsOneWidget);
    expect(find.text(l10n.resultAge), findsOneWidget);
    expect(find.text(l10n.resultHeight), findsOneWidget);
    expect(find.text(l10n.resultWeight), findsOneWidget);
    expect(find.text(l10n.resultGender), findsOneWidget);
    expect(find.text(l10n.deleteSession), findsOneWidget);
  });
}
