// ignore_for_file: scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:six_minute_walk_test/core/presentation/session_export_service.dart';
import 'package:six_minute_walk_test/features/history/history_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

// ------------------------------------------------------------
// Fake export service
// ------------------------------------------------------------

class FakeSessionExportService implements SessionExportService {
  int shareAllSessionsCalls = 0;
  Object? error;

  @override
  Future<void> shareAllSessions({required BuildContext context}) async {
    shareAllSessionsCalls++;

    if (error != null) {
      throw error!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// ------------------------------------------------------------
// Test data
// ------------------------------------------------------------

Profile createTestProfile({
  int id = 1,
  String? name = 'Test Person',
  int age = 30,
  int height = 175,
}) {
  return Profile(
    id: id,
    name: name,
    timestamp: DateTime(2026, 1, 1),
    height: height,
    age: age,
    gender: Gender.other,
    weight: 70,
  );
}

WalkSessionRow createTestSession({
  String id = 'test-session-1',
  WalkPhase phase = WalkPhase.finished,
  Duration duration = const Duration(minutes: 6),
  double distance = 550,
  int profileId = 1,
}) {
  return WalkSessionRow(
    id: id,
    startedAt: DateTime.now(),
    duration: duration,
    distance: distance,
    distanceConfidence: 0.95,
    phase: phase,
    profileId: profileId,
  );
}

WalkSessionWithProfile createTestSessionWithProfile({
  String id = 'test-session-1',
  WalkPhase phase = WalkPhase.finished,
  String? name = 'Test Person',
}) {
  return WalkSessionWithProfile(
    session: createTestSession(id: id, phase: phase),
    profile: createTestProfile(name: name),
  );
}

// ------------------------------------------------------------
// Test helper
// ------------------------------------------------------------

Widget createTestApp({
  required Stream<List<WalkSessionWithProfile>> stream,
  required FakeSessionExportService exportService,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HistoryScreen()),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final session = state.extra as WalkSessionWithProfile;

          return Scaffold(body: Text('Result: ${session.session.id}'));
        },
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      walkSessionsWithProfilesProvider.overrideWith((ref) => stream),
      sessionExportServiceProvider.overrideWithValue(exportService),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

// ------------------------------------------------------------
// Tests
// ------------------------------------------------------------

void main() {
  late FakeSessionExportService exportService;

  setUp(() {
    exportService = FakeSessionExportService();
  });

  group('HistoryScreen', () {
    // --------------------------------------------------------
    // Loading state
    // --------------------------------------------------------

    testWidgets('shows loading indicator while loading', (tester) async {
      final controller = StreamController<List<WalkSessionWithProfile>>();

      await tester.pumpWidget(
        createTestApp(stream: controller.stream, exportService: exportService),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });

    // --------------------------------------------------------
    // Empty state
    // --------------------------------------------------------

    testWidgets('shows empty message when there are no sessions', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(stream: Stream.value([]), exportService: exportService),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(HistoryScreen)),
          )!.historyNoEntries,
        ),
        findsOneWidget,
      );
    });

    // --------------------------------------------------------
    // Session list
    // --------------------------------------------------------

    testWidgets('displays session and profile name', (tester) async {
      final session = createTestSessionWithProfile(name: 'Max Mustermann');

      await tester.pumpWidget(
        createTestApp(
          stream: Stream.value([session]),
          exportService: exportService,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Max Mustermann'), findsOneWidget);

      expect(find.byKey(const ValueKey('test-session-1')), findsOneWidget);
    });

    testWidgets('shows check icon for finished session', (tester) async {
      final session = createTestSessionWithProfile(phase: WalkPhase.finished);

      await tester.pumpWidget(
        createTestApp(
          stream: Stream.value([session]),
          exportService: exportService,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows cancel icon for aborted session', (tester) async {
      final session = createTestSessionWithProfile(phase: WalkPhase.aborted);

      await tester.pumpWidget(
        createTestApp(
          stream: Stream.value([session]),
          exportService: exportService,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows fitness assessment for finished session', (
      tester,
    ) async {
      final session = createTestSessionWithProfile(phase: WalkPhase.finished);

      await tester.pumpWidget(
        createTestApp(
          stream: Stream.value([session]),
          exportService: exportService,
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(HistoryScreen));

      final l10n = AppLocalizations.of(context)!;

      expect(find.textContaining(l10n.historyFit), findsOneWidget);
    });

    testWidgets('does not show fitness assessment for aborted session', (
      tester,
    ) async {
      final session = createTestSessionWithProfile(phase: WalkPhase.aborted);

      await tester.pumpWidget(
        createTestApp(
          stream: Stream.value([session]),
          exportService: exportService,
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(HistoryScreen));

      final l10n = AppLocalizations.of(context)!;

      expect(find.textContaining(l10n.historyFit), findsNothing);
    });

    testWidgets('displays multiple sessions', (tester) async {
      final sessions = [
        createTestSessionWithProfile(id: 'session-1', name: 'Person One'),
        createTestSessionWithProfile(id: 'session-2', name: 'Person Two'),
      ];

      await tester.pumpWidget(
        createTestApp(
          stream: Stream.value(sessions),
          exportService: exportService,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Person One'), findsOneWidget);
      expect(find.text('Person Two'), findsOneWidget);
    });

    // --------------------------------------------------------
    // Navigation
    // --------------------------------------------------------

    testWidgets('navigates to result screen when session is tapped', (
      tester,
    ) async {
      final session = createTestSessionWithProfile();

      await tester.pumpWidget(
        createTestApp(
          stream: Stream.value([session]),
          exportService: exportService,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('test-session-1')));

      await tester.pumpAndSettle();

      expect(find.text('Result: test-session-1'), findsOneWidget);
    });

    // --------------------------------------------------------
    // Export
    // --------------------------------------------------------

    testWidgets('calls export service when share button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(stream: Stream.value([]), exportService: exportService),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));

      await tester.pumpAndSettle();

      expect(exportService.shareAllSessionsCalls, 1);
    });

    testWidgets('shows snackbar when export fails', (tester) async {
      exportService.error = Exception('Export error');

      await tester.pumpWidget(
        createTestApp(stream: Stream.value([]), exportService: exportService),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      expect(find.textContaining('Export error'), findsOneWidget);
    });
  });
}
