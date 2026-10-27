import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:six_minute_walk_test/app/app.dart';
import 'package:six_minute_walk_test/app/router.dart';

void main() {
  testWidgets('home screen offers navigation to the walking test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: SixMinuteWalkApp(locale: Locale('de'))),
    );

    expect(find.text('6-Minuten-Gehtest'), findsOneWidget);
    expect(find.text('Test starten'), findsOneWidget);
    expect(find.text('Meine Ergebnisse'), findsOneWidget);
  });

  testWidgets('clicking start test leads to the patient information screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: SixMinuteWalkApp(locale: Locale('de'))),
    );

    await tester.tap(find.text('Test starten'));
    await tester.pumpAndSettle();

    expect(find.text('Vorkalibrierung'), findsOneWidget);
    expect(find.text('Patienteninformationen'), findsOneWidget);
  });

  testWidgets('unsupported device languages fall back to English', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    tester.platformDispatcher.localeTestValue = const Locale('fr');
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    // The router is global, so an earlier test may have navigated away.
    router.go('/');
    await tester.pumpWidget(const ProviderScope(child: SixMinuteWalkApp()));

    expect(find.text('6-Minute Walk Test'), findsOneWidget);
  });
}
