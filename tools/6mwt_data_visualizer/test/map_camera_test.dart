import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/features/map/session_map.dart';

import 'support/replay_fixtures.dart' as fixtures;

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
  Future<MapCamera> pumpMap(WidgetTester tester, List<dynamic> samples) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionMap(
            session: fixtures.session(samples.cast()),
            tileProvider: _BlankTiles(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return MapCamera.of(tester.element(find.byType(TileLayer)));
  }

  testWidgets('a track with a single distinct position keeps a finite zoom', (
    tester,
  ) async {
    final camera = await pumpMap(tester, [
      fixtures.gps(0, 0.001),
      fixtures.gps(10, 0.001),
    ]);
    expect(camera.zoom.isFinite, isTrue);
    expect(camera.zoom, lessThanOrEqualTo(19));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fit button on a single-position track stays finite', (
    tester,
  ) async {
    await pumpMap(tester, [fixtures.gps(0, 0.001), fixtures.gps(10, 0.001)]);
    await tester.tap(find.byIcon(Icons.fit_screen));
    await tester.pumpAndSettle();
    final camera = MapCamera.of(tester.element(find.byType(TileLayer)));
    expect(camera.zoom.isFinite, isTrue);
    expect(camera.center.latitude.isFinite, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawing while panning and zooming keeps the camera finite', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = fixtures.session([
      fixtures.gps(0, 0),
      fixtures.gps(30, 0.003),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionMap(
            session: source.copyWith(referenceDirectory: 'unused'),
            tileProvider: _BlankTiles(),
            onReferenceSaved: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draw reference'));
    await tester.pumpAndSettle();
    MapCamera camera() => MapCamera.of(tester.element(find.byType(TileLayer)));

    for (var i = 0; i < 6; i++) {
      await tester.tapAt(Offset(300.0 + i * 60, 300));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.drag(
        find.byType(FlutterMap),
        Offset(i.isEven ? 120 : -90, 40),
      );
      await tester.pump();
    }
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    for (final dy in [-4000.0, -4000.0, 4000.0, -4000.0, 20000.0, -20000.0]) {
      await tester.sendEventToBinding(pointer.hover(const Offset(500, 400)));
      await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
      await tester.pump();
      expect(camera().zoom.isFinite, isTrue);
      expect(camera().zoom, inInclusiveRange(2, 24));
    }
    await tester.pumpAndSettle();
    expect(camera().center.latitude.isFinite, isTrue);
    expect(tester.takeException(), isNull);
  });
}
