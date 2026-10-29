import 'package:six_mwt_visualizer/features/estimator_lab/session_replay_cache.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_lab.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimators.dart';

import 'support/replay_fixtures.dart' as fixtures;

String tooltipText(LineTooltipItem item) =>
    TextSpan(text: item.text, children: item.children).toPlainText();

void main() {
  testWidgets('diagnostics expand and collapse inside their distance cell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EstimatorLab(
            replayLoader: (s) async => runSessionReplay(s),
            session: fixtures.session([
              fixtures.gps(0, 0),
              fixtures.gps(5, 0.00005),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Confidence is visible without expanding the diagnostics.
    expect(
      find.textContaining('Confidence: '),
      findsNWidgets(createEstimators().length),
    );
    expect(find.textContaining('Rejected GPS:'), findsNothing);
    final index = createEstimators().indexWhere(
      (e) => e.additionalInfo.containsKey('Rejected GPS'),
    );
    final button = find.byKey(ValueKey('info-0-$index'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('Rejected GPS:'), findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('Rejected GPS:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'partial reference is visible and tooltips include unhit curves in order',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = fixtures.session(
        [
          fixtures.gps(0, 0),
          fixtures.gps(5, 0.00005),
          fixtures.gps(10, 0.0001),
        ],
        reference: fixtures.session([
          fixtures.gps(1, 0, distance: 100),
          fixtures.gps(9, 0.001, distance: 180),
        ]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EstimatorLab(
              replayLoader: (s) async => runSessionReplay(s),
              session: session,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reference (dashed)'), findsOneWidget);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final bars = chart.data.lineBarsData;
      expect(bars.last.spots.map((point) => point.x), [1, 9]);
      final tooltip = chart.data.lineTouchData.touchTooltipData;
      final hit = LineBarSpot(bars.first, 0, bars.first.spots[1]);
      final item = tooltip.getTooltipItems([hit]).single!;
      final text = tooltipText(item);
      expect(text, contains('Reference: 40.00 m'));
      // The configured estimator list can change without changing this test.
      final labels = [
        for (var i = 0; i < createEstimators().length; i++) '#${i + 1}:',
        'Reference:',
      ];
      var previousIndex = -1;
      for (final label in labels) {
        final index = text.indexOf(label);
        expect(index, greaterThan(previousIndex), reason: label);
        previousIndex = index;
      }
      final markers = item.children!.where((span) => span.text == '\n● ');
      expect(
        markers.map((span) => span.style!.color),
        bars.map((bar) => bar.color),
      );
      // Flat step-only curves may have no point at this timestamp. Choose an
      // actual second hit at the same time instead of assuming a list index.
      final otherIndex = bars.indexWhere(
        (bar) => bar != bars.first && bar.spots.any((p) => p.x == hit.x),
      );
      expect(otherIndex, greaterThan(0));
      final other = bars[otherIndex];
      final reversedHits = [
        LineBarSpot(
          other,
          otherIndex,
          other.spots.firstWhere((p) => p.x == hit.x),
        ),
        hit,
      ];
      final items = tooltip.getTooltipItems(reversedHits);
      expect(items, hasLength(2));
      expect(tooltipText(items.first!), text);
      expect(items.last, isNull);
      expect(tooltip.getTooltipItems([]), isEmpty);
      final beforeReference = tooltipText(
        tooltip.getTooltipItems([
          LineBarSpot(bars.first, 0, bars.first.spots.first),
        ]).single!,
      );
      expect(beforeReference, contains('Reference: — (outside recording)'));

      // The table compares the estimator's 1–9 s distance, not its full 0–10 s total.
      final table = tester.widget<DataTable>(find.byType(DataTable));
      for (var i = 0; i < table.rows.length; i++) {
        final label = table.rows[i].cells.first.child as Row;
        expect((label.children.first as Icon).color, bars[i].color);
      }
      final expectedDelta = (bars.first.spots.last.y * 0.8 - 80)
          .toStringAsFixed(2);
      expect(
        find.textContaining('Δ Reference: $expectedDelta m'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('shows graph, diagnostics and readable tooltips in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = ThemeData(brightness: brightness);

      Widget lab(double longitude) => MaterialApp(
        theme: theme,
        home: Scaffold(
          body: EstimatorLab(
            replayLoader: (s) async => runSessionReplay(s),
            session: fixtures.session([
              fixtures.gps(0, 0),
              fixtures.gps(10, longitude),
            ]),
          ),
        ),
      );

      await tester.pumpWidget(lab(1));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.byWidgetPredicate((widget) => widget is DropdownButton),
        findsNothing,
      );
      expect(find.text('Add variant'), findsNothing);
      expect(
        tester.widget<DataTable>(find.byType(DataTable)).rows,
        hasLength(createEstimators().length),
      );
      final gpsDiagnosticsCount = createEstimators()
          .where(
            (estimator) => estimator.additionalInfo.containsKey('Rejected GPS'),
          )
          .length;
      for (final button in tester.widgetList<TextButton>(
        find.byWidgetPredicate((w) => w is TextButton),
      )) {
        button.onPressed?.call();
      }
      await tester.pump();
      expect(
        find.textContaining('Rejected GPS: 1'),
        findsNWidgets(gpsDiagnosticsCount),
      );

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final bar = chart.data.lineBarsData.first;
      final spot = LineBarSpot(bar, 0, bar.spots.last);
      final tooltip = chart.data.lineTouchData.touchTooltipData;
      expect(
        tooltip.getTooltipColor(spot),
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(
        tooltip.getTooltipItems([spot]).single!.textStyle.color,
        theme.colorScheme.onSurface,
      );

      // Changing sessions creates fresh estimators and updates their diagnostics.
      await tester.pumpWidget(lab(0.0001));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rejected GPS:'), findsNothing);
      for (final button in tester.widgetList<TextButton>(
        find.byWidgetPredicate((w) => w is TextButton),
      )) {
        button.onPressed?.call();
      }
      await tester.pump();
      expect(
        find.textContaining('Rejected GPS: 0'),
        findsNWidgets(gpsDiagnosticsCount),
      );
      expect(find.textContaining('Rejected GPS: 1'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
