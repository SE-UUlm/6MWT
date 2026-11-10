import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:six_minute_walk_test/features/home/home_screen.dart';
import 'package:six_minute_walk_test/features/instructions/instructions_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

void main() {
  late GoRouter router;

  Widget createTestApp() {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/instructions',
          builder: (context, state) => const InstructionsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('PROFILE_SCREEN'))),
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
  }

  testWidgets('complete flow from home through all instruction pages', (
    tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    addTearDown(router.dispose);

    await tester.pumpAndSettle();

    // ---------- HOME SCREEN ----------

    BuildContext context = tester.element(find.byType(HomeScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.appTitle), findsOneWidget);
    expect(find.text(l10n.appSubTitle), findsOneWidget);

    expect(find.text(l10n.home_walk), findsOneWidget);
    expect(find.text(l10n.home_performance), findsOneWidget);
    expect(find.text(l10n.home_progress), findsOneWidget);

    expect(find.text(l10n.startTest), findsOneWidget);

    expect(find.text(l10n.home_result), findsOneWidget);
    expect(find.text(l10n.home_instruction), findsOneWidget);

    // ---------- INSTRUCTIONS ----------
    await tester.ensureVisible(find.text(l10n.home_instruction));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.home_instruction));
    await tester.pumpAndSettle();

    // ---------- PAGE 1 ----------

    expect(find.text(l10n.instructions_1_welc), findsOneWidget);
    expect(find.text(l10n.instructions_1_text), findsOneWidget);

    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();

    // ---------- PAGE 2 ----------

    expect(find.text(l10n.instructions_2_welc), findsOneWidget);

    expect(find.text(l10n.bulletPoint_1), findsOneWidget);
    expect(find.text(l10n.bulletPoint_2), findsOneWidget);
    expect(find.text(l10n.bulletPoint_3), findsOneWidget);
    expect(find.text(l10n.bulletPoint_4), findsOneWidget);
    expect(find.text(l10n.bulletPoint_5), findsOneWidget);

    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();

    // ---------- PAGE 3 ----------

    expect(find.text(l10n.instructions_3_heading), findsOneWidget);
    expect(find.text(l10n.instructions_3_text), findsOneWidget);
    expect(find.text(l10n.instructions_3_range), findsOneWidget);

    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();

    // ---------- PAGE 4 ----------

    expect(find.text(l10n.instructions_4_welc), findsOneWidget);
    expect(find.text(l10n.instructions_4_outdoor), findsOneWidget);
    expect(find.text(l10n.instructions_4_pocket), findsOneWidget);
    expect(find.text(l10n.instructions_4_walk), findsOneWidget);
    expect(find.text(l10n.instructions_4_timer), findsOneWidget);
    expect(find.text(l10n.instructions_4_pause), findsOneWidget);

    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();

    // ---------- PAGE 5 ----------

    expect(find.text(l10n.instructions_5_welc), findsOneWidget);
    expect(find.text(l10n.instructions_5_text), findsOneWidget);
    expect(find.text(l10n.instructions_5_chest), findsOneWidget);
    expect(find.text(l10n.instructions_5_dizzy), findsOneWidget);
    expect(find.text(l10n.instructions_5_breath), findsOneWidget);
    expect(find.text(l10n.instructions_5_doctor), findsOneWidget);

    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();

    // ---------- PAGE 6 ----------

    expect(find.text(l10n.instructions_6_welc), findsOneWidget);
    expect(find.text(l10n.instructions_6_text), findsOneWidget);

    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();

    // ---------- PAGE 7 ----------

    expect(find.text(l10n.instructions_7_welc), findsOneWidget);
    expect(find.text(l10n.instructions_7_text), findsOneWidget);

    expect(find.text(l10n.startTest), findsOneWidget);

    await tester.tap(find.text(l10n.startTest));
    await tester.pumpAndSettle();

    // ---------- PROFILE SCREEN ----------

    expect(find.text('PROFILE_SCREEN'), findsOneWidget);
  });
}
