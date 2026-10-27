import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/features/instructions/instructions_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import '../../helpers/localized_app.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final headings = [
    l10n.instructions_1_welc,
    l10n.instructions_2_welc,
    l10n.instructions_3_heading,
    l10n.instructions_4_welc,
    l10n.instructions_5_welc,
    l10n.instructions_6_welc,
    l10n.instructions_7_welc,
  ];

  Future<void> showInstructions(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'instructions',
              builder: (_, _) => const InstructionsScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(localizedRouterApp(router: router));
    router.push('/instructions');
    await tester.pumpAndSettle();
  }

  /// Index of the highlighted (wide) dot in the page indicator.
  int activeDot(WidgetTester tester) {
    final dots = find.byType(AnimatedContainer);
    expect(dots, findsNWidgets(headings.length));
    final widths = List.generate(
      headings.length,
      (i) => tester.getSize(dots.at(i)).width,
    );
    final maxWidth = widths.reduce((a, b) => a > b ? a : b);
    expect(widths.where((width) => width == maxWidth), hasLength(1));
    return widths.indexOf(maxWidth);
  }

  void expectPage(WidgetTester tester, int page) {
    expect(find.text(headings[page]), findsOneWidget);
    expect(activeDot(tester), page);
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapBackArrow(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
  }

  testWidgets('continue walks through all pages and returns home', (
    tester,
  ) async {
    await showInstructions(tester);

    for (var page = 0; page < headings.length; page++) {
      expectPage(tester, page);
      await tapContinue(tester);
    }

    expect(find.byType(InstructionsScreen), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('back arrow goes to the previous page, then leaves', (
    tester,
  ) async {
    await showInstructions(tester);
    await tapContinue(tester);
    await tapContinue(tester);
    expectPage(tester, 2);

    await tapBackArrow(tester);
    expectPage(tester, 1);
    await tapBackArrow(tester);
    expectPage(tester, 0);

    await tapBackArrow(tester);
    expect(find.byType(InstructionsScreen), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('system back goes to the previous page, then leaves', (
    tester,
  ) async {
    await showInstructions(tester);
    await tapContinue(tester);
    expectPage(tester, 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expectPage(tester, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(InstructionsScreen), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('swiping changes the page and indicator', (tester) async {
    await showInstructions(tester);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();
    expectPage(tester, 1);
  });
}
