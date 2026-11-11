import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import 'package:six_minute_walk_test/features/home/home_screen.dart';
import 'package:six_minute_walk_test/features/instructions/instructions_screen.dart';

/// Widget tests for the HomeScreen

/// These tests verify that:
/// - The HomeScreen and its main buttons are displayed correctly.
/// - The Start button navigates to the Profile screen.
/// - The Info button is available.
/// - The Results card navigates to the History screen.
/// - The Instructions card opens the InstructionsScreen
///   and displays the first instruction page.
///
/// A test GoRouter with placeholder screens is used to
/// verify navigation independently of the full application.
void main() {
  /// Erstellt einen Router für unsere Widget-Tests.
  GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

        // Test-Zielseite für den Start-Button
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            return const Scaffold(body: Center(child: Text('PROFILE SCREEN')));
          },
        ),

        // Test-Zielseite für den Info-Button
        GoRoute(
          path: '/about',
          builder: (context, state) {
            return const Scaffold(body: Center(child: Text('ABOUT SCREEN')));
          },
        ),

        // Test-Zielseite für Ergebnisse
        GoRoute(
          path: '/history',
          builder: (context, state) {
            return const Scaffold(body: Center(child: Text('HISTORY SCREEN')));
          },
        ),

        // Test-Zielseite für Anleitungen
        GoRoute(
          path: '/instructions',
          builder: (context, state) =>
              const InstructionsScreen(offerTestStart: true),
        ),
      ],
    );
  }

  /// Baut die App für einen Widget-Test.
  Widget createTestApp() {
    final router = createRouter();

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,

        // Lokalisierung
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen wird angezeigt', (tester) async {
      await tester.pumpWidget(createTestApp());

      await tester.pumpAndSettle();

      // Prüfen, ob der HomeScreen geladen wurde.
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Info Button wird angezeigt', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Den Info-Button anhand seines Tooltips finden.
      final infoButton = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip != null,
      );

      expect(infoButton, findsOneWidget);
    });

    testWidgets('Start Button wird angezeigt', (tester) async {
      await tester.pumpWidget(createTestApp());

      await tester.pumpAndSettle();

      // Der Play-Button sollte vorhanden sein.
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('Start Button navigiert zu Profile', (tester) async {
      await tester.pumpWidget(createTestApp());

      await tester.pumpAndSettle();

      // Start-Button über sein Play-Icon finden und klicken.
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));

      await tester.pumpAndSettle();

      // Prüfen, ob die Profile-Seite angezeigt wird.
      expect(find.text('PROFILE SCREEN'), findsOneWidget);
    });

    testWidgets('Info Button wird angezeigt', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Den Info-Button anhand seines Tooltips finden.
      final infoButton = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip != null,
      );

      expect(infoButton, findsOneWidget);
    });

    testWidgets('Ergebnisse Card navigiert zu History', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Lokalisierte Bezeichnung der Ergebnisse-Card ermitteln.
      final context = tester.element(find.byType(HomeScreen));
      final l10n = AppLocalizations.of(context)!;

      final historyCard = find.text(l10n.home_result);

      // Card sichtbar machen.
      await tester.ensureVisible(historyCard);
      await tester.pumpAndSettle();

      // Ergebnisse-Card anklicken.
      await tester.tap(historyCard);
      await tester.pumpAndSettle();

      // Prüfen, ob die History-Route geöffnet wurde.
      expect(find.text('HISTORY SCREEN'), findsOneWidget);
    });

    testWidgets('Anleitungen Card navigiert zur ersten Anleitungsseite', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      await tester.pumpAndSettle();

      // Anleitungen-Card finden
      final instructionCard = find.text(
        AppLocalizations.of(
          tester.element(find.byType(HomeScreen)),
        )!.home_instruction,
      );

      // Zur Card scrollen und klicken
      await tester.ensureVisible(instructionCard);
      await tester.tap(instructionCard);

      await tester.pumpAndSettle();

      // Prüfen, ob die echte InstructionsScreen geöffnet wurde
      expect(find.byType(InstructionsScreen), findsOneWidget);

      // Prüfen, ob die erste Anleitungsseite angezeigt wird
      expect(
        find.text(
          lookupAppLocalizations(const Locale('en')).instructions_1_welc,
        ),
        findsOneWidget,
      );
    });
  });
}
