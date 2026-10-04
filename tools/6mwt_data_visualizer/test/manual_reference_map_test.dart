import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/core/domain/session.dart';
import 'package:six_mwt_visualizer/features/map/gps_track_layer.dart';
import 'package:six_mwt_visualizer/features/map/session_map.dart';

import 'estimator_replay_test.dart' as fixtures;

class _BlankTiles extends TileProvider {
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

void main() {
  testWidgets('click, undo, cancel, save and reload a route on the map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final folder = Directory.systemTemp.createTempSync('visualizer-map-');
    addTearDown(() => folder.deleteSync(recursive: true));
    final source = fixtures.session([
      fixtures.gps(0, 0),
      fixtures.gps(30, 0.003),
    ]);
    final session = source.copyWith(
      referenceDirectory: '${folder.path}/references',
      references: [source.copyWith(referenceName: 'Watch')],
    );
    Session? saved;
    var displayed = session;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SessionMap(
              session: displayed,
              tileProvider: _BlankTiles(),
              onReferenceSaved: (updated) => setState(() {
                saved = updated;
                displayed = updated;
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draw reference'));
    await tester.pumpAndSettle();
    Future<void> addPoint(Offset offset) async {
      await tester.tapAt(offset);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
    }

    await addPoint(const Offset(400, 300));
    await addPoint(const Offset(550, 400));
    expect(
      tester.widget<Text>(find.textContaining('Click the map')).data,
      contains('2 points'),
    );
    await tester.tap(find.byTooltip('Undo last point'));
    await tester.pump();
    expect(find.textContaining('1 points'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(Directory(session.referenceDirectory!).existsSync(), isFalse);
    await tester.tap(find.text('Draw reference'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0 points'), findsOneWidget);
    await addPoint(const Offset(400, 300));
    await addPoint(const Offset(550, 400));
    await tester.enterText(find.byType(TextField), 'My clicked route');
    // Let real file I/O finish outside the widget test's fake clock.
    await tester.runAsync(() async {
      await tester.tap(find.text('Save reference'));
      for (var i = 0; i < 100 && saved == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.references, hasLength(2));
    final reference = saved!.references.last;
    expect(reference.referenceName, 'My clicked route');
    expect(reference.distance, greaterThan(0));
    expect(reference.positionSamples, hasLength(2));
    expect(find.byType(GpsTrackLayer), findsNWidgets(3));
    expect(find.text('Reference saved.'), findsOneWidget);
    final files = Directory(session.referenceDirectory!).listSync();
    expect(files, hasLength(1));
    final loaded = await tester.runAsync(
      () => SessionLoader.load(files.single.path),
    );
    expect(loaded!.sessions.single.referenceName, 'My clicked route');
    expect(tester.takeException(), isNull);
  });
}
