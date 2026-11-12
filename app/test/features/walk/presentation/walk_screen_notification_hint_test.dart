import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/app/notification_providers.dart';
import 'package:six_minute_walk_test/core/notifications/local_notification_service.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_screen.dart';

import '../../../helpers/fake_sensors.dart';
import '../../../helpers/localized_app.dart';
import '../../../helpers/logs.dart';

/// Reports a configurable permission state instead of asking the platform.
class FakeNotificationService extends LocalNotificationService {
  FakeNotificationService({this.enabled = true, this.failing = false})
    : super(channelName: 'test', channelDescription: 'test');

  bool enabled;
  final bool failing;
  int checks = 0;

  @override
  Future<bool> areNotificationsEnabled() async {
    checks++;
    if (failing) {
      throw StateError('check failed');
    }
    return enabled;
  }
}

const _androidHint =
    'Notifications are turned off, so the end of the test is signaled by '
    'vibration only, without sound. You can turn on notifications in the '
    'settings.';

const _iosHint =
    'Notifications are turned off, so there will be no sound or vibration at '
    'the end of the test. You can turn on notifications in the settings.';

void main() {
  late WalkSession session;

  Future<void> pumpWalkScreen(
    WidgetTester tester,
    FakeNotificationService service,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    session = WalkSession(
      sources: [FakeSensorSource()],
      distanceEstimator: GpsDistanceEstimator(),
      now: () => tester.binding.clock.now(),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walkSessionProvider.overrideWithValue(session),
          localNotificationServiceProvider.overrideWithValue(service),
        ],
        child: localizedApp(
          locale: const Locale('en'),
          home: const WalkScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows no hint when notifications are enabled', (tester) async {
    await pumpWalkScreen(tester, FakeNotificationService());

    expect(find.text(_androidHint), findsNothing);
    expect(find.text(_iosHint), findsNothing);
  });

  testWidgets('tells Android users that only vibration remains', (
    tester,
  ) async {
    await pumpWalkScreen(tester, FakeNotificationService(enabled: false));

    expect(find.text(_androidHint), findsOneWidget);
    expect(find.text(_iosHint), findsNothing);
  });

  testWidgets('tells iOS users that there is no signal at all', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpWalkScreen(tester, FakeNotificationService(enabled: false));

      expect(find.text(_iosHint), findsOneWidget);
      expect(find.text(_androidHint), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('rechecks the permission when the app resumes', (tester) async {
    final service = FakeNotificationService(enabled: false);
    await pumpWalkScreen(tester, service);
    expect(find.text(_androidHint), findsOneWidget);

    // The user enables notifications in the system settings and returns.
    service.enabled = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(service.checks, 2);
    expect(find.text(_androidHint), findsNothing);
  });

  testWidgets('shows no hint when the permission cannot be checked', (
    tester,
  ) async {
    silenceLogs();

    await pumpWalkScreen(tester, FakeNotificationService(failing: true));

    expect(find.text(_androidHint), findsNothing);
    expect(find.text(_iosHint), findsNothing);
  });
}
