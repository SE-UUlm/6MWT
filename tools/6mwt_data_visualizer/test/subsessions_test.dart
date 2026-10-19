import 'package:six_mwt_visualizer/features/estimator_lab/session_replay_cache.dart';
import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/core/domain/session.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_lab.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimators.dart';
import 'package:six_mwt_visualizer/features/map/gps_track_layer.dart';
import 'package:six_mwt_visualizer/features/map/session_map.dart';
import 'support/replay_fixtures.dart' as fixtures;

class BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );
}

void desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Session group() {
  final devices = [
    for (var i = 0; i < 3; i++)
      fixtures
          .session([fixtures.gps(0, 0), fixtures.gps(10, .0001 * (i + 1))])
          .copyWith(sourcePath: '/walk/session_phone$i.json'),
  ];
  return devices.first.copyWith(
    id: 'group',
    notes: 'Together',
    subsessions: devices,
  );
}

void main() {
  test(
    'folder groups five identical session IDs and preserves references on save',
    () async {
      final root = await Directory.systemTemp.createTemp('subsessions-');
      addTearDown(() => root.delete(recursive: true));
      final folder = await Directory('${root.path}/Together').create();
      final recording = fixtures.session([
        fixtures.gps(0, 0),
        fixtures.gps(10, .0001),
      ]);
      for (var i = 0; i < 5; i++) {
        await File(
          '${folder.path}/session_$i.json',
        ).writeAsString(jsonEncode(recording.toReferenceJson()));
      }
      await File(
        '${folder.path}/reference.json',
      ).writeAsString(jsonEncode(recording.toReferenceJson()));
      final data = await SessionLoader.load(root.path);
      expect(data.sessions, hasLength(1));
      final session = data.sessions.single;
      expect(session.notes, 'Together');
      expect(session.subsessions, hasLength(5));
      expect(
        session.subsessions.map((s) => s.sourcePath).toSet(),
        hasLength(5),
      );
      expect(session.subsessions.every((s) => s.hasReference), isTrue);
      final direct = await SessionLoader.load(folder.path);
      expect(direct.sessions.single.subsessions, hasLength(5));
      final selected = await SessionLoader.load(
        '${folder.path}/session_0.json',
      );
      expect(selected.sessions.single.isGroup, isFalse);
      final updated = await SessionLoader.saveReference(
        session,
        recording.copyWith(referenceName: 'New'),
      );
      expect(
        updated.subsessions.every((s) => s.references.length == 2),
        isTrue,
      );
      final reloaded = await SessionLoader.load(folder.path);
      expect(
        reloaded.sessions.single.subsessions.every(
          (s) => s.references.length == 2,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'map starts with every subsession and toggles tracks independently',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionMap(session: group(), tileProvider: BlankTiles()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.byType(GpsTrackLayer), findsNWidgets(3));
      final chips = find.byType(FilterChip);
      await tester.tap(chips.at(1));
      await tester.pumpAndSettle();
      expect(find.byType(GpsTrackLayer), findsNWidgets(2));
      expect(
        tester
            .widgetList<GpsTrackLayer>(find.byType(GpsTrackLayer))
            .map((w) => w.session.deviceLabel),
        ['phone0', 'phone2'],
      );
      await tester.tap(chips.at(1));
      await tester.pumpAndSettle();
      expect(find.byType(GpsTrackLayer), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lab runs each device independently and supports all three graph selections',
    (tester) async {
      desktop(tester);
      final session = group();
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
      final count = createEstimators().length;
      List<LineChartBarData> bars() =>
          tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData;
      expect(bars(), hasLength(count * 3));
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.columns, hasLength(4));
      expect(table.rows, hasLength(count));
      for (var r = 0; r < 3; r++) {
        final expected = EstimatorReplay(
          session.subsessions[r],
        ).run(createEstimators().first).distance;
        expect(bars()[r * count].spots.last.y, expected);
        final cell = find.byWidget(table.rows.first.cells[r + 1].child);
        expect(
          find.descendant(
            of: cell,
            matching: find.text('${expected!.toStringAsFixed(2)} m'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: cell, matching: find.textContaining('Δ stored:')),
          findsOneWidget,
        );
      }
      await tester.tap(find.text('All estimators and subsessions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All estimators of one subsession').last);
      await tester.pumpAndSettle();
      expect(bars(), hasLength(count));
      final recordingDropdown = tester
          .widgetList<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .last;
      recordingDropdown.onChanged!(2);
      await tester.pumpAndSettle();
      final expected = EstimatorReplay(
        session.subsessions[2],
      ).run(createEstimators().first).distance;
      expect(bars().first.spots.last.y, expected);
      await tester.tap(find.text('All estimators of one subsession'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All subsessions of one estimator').last);
      await tester.pumpAndSettle();
      expect(bars(), hasLength(3));
      final estimatorDropdown = tester
          .widgetList<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .last;
      estimatorDropdown.onChanged!(1);
      await tester.pumpAndSettle();
      for (var r = 0; r < 3; r++) {
        expect(
          bars()[r].spots.last.y,
          EstimatorReplay(
            session.subsessions[r],
          ).run(createEstimators()[1]).distance,
        );
      }
      expect(
        tester.widget<DataTable>(find.byType(DataTable)).columns,
        hasLength(4),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
