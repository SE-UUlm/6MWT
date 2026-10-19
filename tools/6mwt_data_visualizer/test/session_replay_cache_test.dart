import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_lab.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/session_replay_cache.dart';
import 'support/replay_fixtures.dart' as fixtures;

void main() {
  final a = fixtures.session([fixtures.gps(0, 0), fixtures.gps(10, .0001)]);
  final b = fixtures.session([fixtures.gps(0, 0), fixtures.gps(10, .0002)]);

  test('background replay preserves every point and diagnostic', () async {
    final expected = runSessionReplay(a);
    final cache = SessionReplayCache();
    final pending = cache.load(a);
    expect(identical(cache.load(a), pending), isTrue);
    final actual = await pending;
    expect(actual.runs.single.length, expected.runs.single.length);
    for (var i = 0; i < actual.runs.single.length; i++) {
      final result = actual.runs.single[i], baseline = expected.runs.single[i];
      expect(result.error, baseline.error);
      expect(
        result.points.map((p) => (p.seconds, p.meters)),
        baseline.points.map((p) => (p.seconds, p.meters)),
      );
      expect(result.additionalInfo, baseline.additionalInfo);
    }
    expect(identical(await cache.load(a), actual), isTrue);
  });

  test('cache distinguishes same-ID recordings and retries failures', () async {
    var calls = 0;
    final cache = SessionReplayCache(
      loader: (session) {
        if (++calls == 1) throw StateError('failed');
        return Future.value(runSessionReplay(session));
      },
    );
    await expectLater(cache.load(a), throwsStateError);
    final first = await cache.load(a);
    expect(await cache.load(a), same(first));
    final other = await cache.load(b);
    expect(
      other.runs.first.first.distance,
      isNot(first.runs.first.first.distance),
    );
    expect(calls, 3);
    await cache.load(a.copyWith(notes: 'reloaded'));
    expect(calls, 4);
  });

  testWidgets('switching sessions ignores stale work and disposal is safe', (
    tester,
  ) async {
    final pendingA = Completer<SessionReplayResult>();
    final pendingB = Completer<SessionReplayResult>();
    Widget lab(bool first) => MaterialApp(
      home: Scaffold(
        body: EstimatorLab(
          session: first ? a : b,
          replayLoader: (s) =>
              identical(s, a) ? pendingA.future : pendingB.future,
        ),
      ),
    );
    await tester.pumpWidget(lab(true));
    expect(find.text('Calculating estimators…'), findsOneWidget);
    await tester.pumpWidget(lab(false));
    pendingA.complete(runSessionReplay(a));
    await tester.pump();
    expect(find.text('Calculating estimators…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    pendingB.complete(runSessionReplay(b));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('background errors offer a working retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EstimatorLab(
            session: a,
            replayLoader: (s) async {
              if (++calls == 1) throw StateError('test failure');
              return runSessionReplay(s);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not replay session:'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
}
