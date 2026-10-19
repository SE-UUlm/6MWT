import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_session_lifecycle.dart';

class ObservedSession extends WalkSession {
  ObservedSession(DateTime Function() now)
    : super(sources: [], distanceEstimator: GpsDistanceEstimator(), now: now);

  int synchronizations = 0;

  @override
  void synchronizeWithClock() {
    synchronizations++;
    super.synchronizeWithClock();
  }
}

Future<void> resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

void main() {
  testWidgets('resume does not create a session', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var creations = 0;
    final container = ProviderContainer(
      overrides: [
        walkSessionProvider.overrideWith((ref) {
          creations++;
          throw StateError('Must not initialize on resume');
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const WalkSessionLifecycle(child: SizedBox()),
      ),
    );
    await resume(tester);
    expect(creations, 0);
    expect(container.exists(walkSessionProvider), isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'resume synchronizes across navigation and listener is disposed',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var now = DateTime.utc(2026, 10, 19);
      final session = ObservedSession(() => now);
      final container = ProviderContainer(
        overrides: [walkSessionProvider.overrideWithValue(session)],
      );
      addTearDown(() async {
        container.dispose();
        await session.dispose();
      });
      container.read(walkSessionProvider);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigator,
            builder: (context, child) => WalkSessionLifecycle(child: child!),
            home: const Scaffold(body: Text('Walk')),
          ),
        ),
      );
      await session.start();
      navigator.currentState!.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Other screen'), findsOneWidget);
      now = now.add(const Duration(minutes: 2));
      await resume(tester);
      expect(session.state.remainingTime, const Duration(minutes: 4));
      now = now.add(const Duration(minutes: 4));
      await resume(tester);
      expect(session.state.phase, WalkPhase.finished);
      final calls = session.synchronizations;
      await tester.pumpWidget(const SizedBox());
      await resume(tester);
      expect(session.synchronizations, calls);
    },
  );
}
