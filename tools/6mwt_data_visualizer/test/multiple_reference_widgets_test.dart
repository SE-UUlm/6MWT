import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:six_mwt_visualizer/core/domain/manual_reference.dart';
import 'package:six_mwt_visualizer/core/theme/reference_colors.dart';
import 'package:six_mwt_visualizer/features/chart/distance_steps_chart.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_lab.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimators.dart';

import 'estimator_replay_test.dart' as fixtures;

void main() {
  final session = fixtures.session([
    fixtures.gps(0, 0),
    fixtures.gps(30, 0.003),
  ]);
  final watch = fixtures
      .session([
        fixtures.gps(5, 0, distance: 10),
        fixtures.gps(25, 0.001, distance: 90),
      ])
      .copyWith(referenceName: 'Watch');
  final manual = createManualReference(session, [
    const LatLng(0, 0),
    const LatLng(0, 0.003),
  ], 'Drawn route');
  final original = session.copyWith(references: [watch]);
  final updated = original.copyWith(references: [watch, manual]);

  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'recording chart refreshes same session and toggles each reference',
    (tester) async {
      desktop(tester);
      Widget chart(bool added) => MaterialApp(
        home: Scaffold(
          body: DistanceStepsChart(session: added ? updated : original),
        ),
      );
      await tester.pumpWidget(chart(false));
      expect(
        tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData,
        hasLength(2),
      );
      await tester.pumpWidget(chart(true));
      await tester.pumpAndSettle();
      var bars = tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData;
      expect(bars, hasLength(3));
      expect(bars[1].color, referenceColor(0));
      expect(bars[2].color, referenceColor(1));
      expect(find.text('Drawn route (constant speed)'), findsOneWidget);
      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();
      bars = tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData;
      expect(bars, hasLength(2));
      expect(bars.last.color, referenceColor(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lab compares each overlap and keeps reference tooltip names and colors',
    (tester) async {
      desktop(tester);
      Widget lab(bool added) => MaterialApp(
        home: Scaffold(body: EstimatorLab(session: added ? updated : original)),
      );
      await tester.pumpWidget(lab(false));
      await tester.pumpWidget(lab(true));
      await tester.pumpAndSettle();
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final bars = chart.data.lineBarsData;
      final count = createEstimators().length;
      expect(bars, hasLength(count + 2));
      expect(bars[count].color, referenceColor(0));
      expect(bars[count + 1].color, referenceColor(1));
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.columns, hasLength(8));
      expect(table.rows, hasLength(count + 2));
      final watchRow = table.rows[count];
      final manualRow = table.rows[count + 1];
      expect(find.text('Reference: Watch'), findsOneWidget);
      expect(
        find.text('Reference: Drawn route (constant speed)'),
        findsOneWidget,
      );
      expect((watchRow.cells[1].child as Text).data, '80.00');
      expect(
        (manualRow.cells[1].child as Text).data,
        manual.distance.toStringAsFixed(2),
      );
      expect(
        ((watchRow.cells.first.child as Row).children.first as Icon).color,
        referenceColor(0),
      );
      expect(
        ((manualRow.cells.first.child as Row).children.first as Icon).color,
        referenceColor(1),
      );
      expect((watchRow.cells.last.child as Text).data, contains('5.0–25.0 s'));
      final fullDistance = bars.first.spots.last.y;
      final cells = table.rows.first.cells;
      expect(
        (cells[3].child as Text).data,
        (fullDistance * 20 / 30 - 80).toStringAsFixed(2),
      );
      expect(
        (cells[5].child as Text).data,
        (fullDistance - manual.distance).toStringAsFixed(2),
      );
      final item = chart.data.lineTouchData.touchTooltipData.getTooltipItems([
        LineBarSpot(bars.last, bars.length - 1, const FlSpot(15, 0)),
      ]).single!;
      final tooltip = TextSpan(
        text: item.text,
        children: item.children,
      ).toPlainText();
      expect(tooltip, contains('Watch: 40.00 m'));
      expect(tooltip, contains('Drawn route (constant speed):'));
      await tester.tap(find.text('Watch (dashed)'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData,
        hasLength(count + 1),
      );
      expect(find.text('Reference: Watch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
