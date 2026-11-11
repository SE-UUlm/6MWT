import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:six_minute_walk_test/l10n/app_localizations.dart';

// Passe diesen Import an den tatsächlichen Speicherort an.
import 'package:six_minute_walk_test/features/walk/presentation/quick_guide_screen.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/quick-guide',
      routes: [
        GoRoute(
          path: '/quick-guide',
          builder: (context, state) => const QuickGuideScreen(),
        ),
        GoRoute(
          path: '/instructions',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Instructions route reached')),
          ),
        ),
        GoRoute(
          path: '/walk',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Walk route reached'))),
        ),
      ],
    );
  });

  tearDown(() {
    router.dispose();
  });

  Future<void> createTestApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('QuickGuide displays all required UI elements', (tester) async {
    await createTestApp(tester);

    final context = tester.element(find.byType(QuickGuideScreen));
    final l10n = AppLocalizations.of(context)!;

    // Screen
    expect(find.byType(Scaffold), findsOneWidget);

    // AppBar
    expect(find.text(l10n.quickGuide_title), findsOneWidget);

    // All four step icons
    expect(find.byIcon(Icons.forest_rounded), findsOneWidget);
    expect(find.byIcon(Icons.phone_iphone_rounded), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    // All four step descriptions
    expect(find.text(l10n.quickGuide_step_outdoor), findsOneWidget);
    expect(find.text(l10n.quickGuide_step_pocket), findsOneWidget);
    expect(find.text(l10n.quickGuide_step_walk), findsOneWidget);
    expect(find.text(l10n.quickGuide_step_end), findsOneWidget);

    // Additional information button
    expect(find.text(l10n.quickGuide_more_info), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

    // Health disclaimer
    expect(find.text(l10n.quickGuide_disclaimer), findsOneWidget);
    expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);

    // Continue button
    expect(find.text(l10n.continueButton), findsOneWidget);
  });

  testWidgets('More information button opens instructions', (tester) async {
    await createTestApp(tester);

    final context = tester.element(find.byType(QuickGuideScreen));
    final l10n = AppLocalizations.of(context)!;

    final infoButton = find.widgetWithText(
      TextButton,
      l10n.quickGuide_more_info,
    );

    await tester.ensureVisible(infoButton);
    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    expect(find.text('Instructions route reached'), findsOneWidget);
  });

  testWidgets('Continue button opens walk screen', (tester) async {
    await createTestApp(tester);

    final context = tester.element(find.byType(QuickGuideScreen));
    final l10n = AppLocalizations.of(context)!;

    final continueButton = find.widgetWithText(
      ElevatedButton,
      l10n.continueButton,
    );

    // Button in den sichtbaren Bereich scrollen
    await tester.ensureVisible(continueButton);
    await tester.pumpAndSettle();

    // Button anklicken
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Walk route reached'), findsOneWidget);
  });
}
