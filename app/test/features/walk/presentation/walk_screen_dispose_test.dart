import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_screen.dart';

class DelayedStopSession extends WalkSession {
  DelayedStopSession()
    : super(sources: [], distanceEstimator: GpsDistanceEstimator());

  final stopped = Completer<void>();
  int stopCalls = 0;

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> stopWarmUp() {
    stopCalls++;
    return stopped.future;
  }
}

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      'screen disposes before warm-up stop completes (fails=$fails)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final session = DelayedStopSession();
        addTearDown(() async {
          await session.dispose();
          await db.close();
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              walkSessionProvider.overrideWithValue(session),
            ],
            child: const MaterialApp(home: WalkScreen(profileId: 1)),
          ),
        );
        final view = tester.widget<PageView>(find.byType(PageView));
        final controller = view.controller!;
        await tester.pumpWidget(const SizedBox());
        expect(session.stopCalls, 1);
        expect(session.stopped.isCompleted, isFalse);
        // ChangeNotifier rejects new listeners after synchronous disposal.
        expect(() => controller.addListener(() {}), throwsFlutterError);
        if (fails) {
          session.stopped.completeError(StateError('sensor stop failed'));
        } else {
          session.stopped.complete();
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
