import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:six_mwt_visualizer/core/domain/session.dart';
import 'package:six_mwt_visualizer/features/map/step_marker_layer.dart';
import 'estimator_replay_test.dart' as fixtures;

void main() {
  test(
    'dense and sparse samples fill comparable screen space without collisions',
    () {
      List<Offset> layout(double spacing, Size size) {
        final grid = ScreenLabelPlacement(
          viewport: Offset.zero & size,
          labelSize: const Size(64, 36),
        );
        return [
          for (double x = 0; x < size.width; x += spacing)
            if (grid.add(Offset(x, 80))) Offset(x, 80),
        ];
      }

      final dense = layout(1, const Size(800, 300));
      final sparse = layout(20, const Size(800, 300));
      expect(dense.length, greaterThan(8));
      expect((dense.length - sparse.length).abs(), lessThanOrEqualTo(2));
      expect(layout(1, const Size(400, 300)).length, lessThan(dense.length));
      for (var i = 1; i < dense.length; i++) {
        expect(dense[i].dx - dense[i - 1].dx, greaterThanOrEqualTo(68));
      }
    },
  );

  test(
    'placement rejects clipped labels, repeated positions and invalid offsets',
    () {
      final grid = ScreenLabelPlacement(
        viewport: const Rect.fromLTWH(0, 0, 200, 100),
        labelSize: const Size(64, 36),
      );
      expect(grid.add(const Offset(10, 80)), isFalse);
      expect(grid.add(const Offset(100, 20)), isFalse);
      expect(grid.add(const Offset(190, 80)), isFalse);
      expect(grid.add(const Offset(100, 110)), isFalse);
      expect(grid.add(const Offset(double.nan, 80)), isFalse);
      expect(grid.add(const Offset(100, 80)), isTrue);
      expect(grid.add(const Offset(100, 80)), isFalse);
      expect(grid.add(const Offset(120, 70)), isFalse);
    },
  );

  testWidgets('screen-space labels adapt to zoom, rotation, pan and resize', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MapController();
    addTearDown(controller.dispose);
    final recording = fixtures.session([
      for (var i = 0; i <= 200; i++) ...[
        fixtures.steps(i, 100 + i * 2.0),
        fixtures.gps(i, i * .00001),
      ],
    ]);
    Widget map(Size size, {List<Session>? sessions, double textScale = 1}) =>
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.fromSize(
                size: size,
                child: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: FlutterMap(
                    mapController: controller,
                    options: const MapOptions(
                      initialCenter: LatLng(0, .001),
                      initialZoom: 18,
                    ),
                    children: [
                      StepMarkerLayer(sessions: sessions ?? [recording]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    List<Marker> labels() => tester
        .widget<MarkerLayer>(find.byType(MarkerLayer))
        .markers
        .where((m) => m.alignment == Alignment.topCenter)
        .toList();
    void checkBoundsAndCollisions() {
      final bounds = <Rect>[];
      final viewport = Offset.zero & controller.camera.nonRotatedSize;
      for (final marker in labels()) {
        final offset = controller.camera.latLngToScreenOffset(marker.point);
        final rect = Rect.fromLTWH(
          offset.dx - marker.width / 2,
          offset.dy - marker.height,
          marker.width,
          marker.height,
        );
        expect(viewport.contains(rect.topLeft), isTrue);
        expect(viewport.contains(rect.bottomRight), isTrue);
        expect(
          bounds.every((other) => !other.overlaps(rect.inflate(3))),
          isTrue,
        );
        expect(marker.rotate, isTrue);
        bounds.add(rect);
      }
    }

    await tester.pumpWidget(map(const Size(800, 500)));
    await tester.pumpAndSettle();
    final initialCount = labels().length;
    expect(initialCount, greaterThan(3));
    checkBoundsAndCollisions();
    // The skipped samples must not be added to the displayed delta.
    final messages = tester
        .widgetList<Tooltip>(find.byType(Tooltip))
        .map((t) => t.message ?? '')
        .where((t) => t.startsWith('GPS segment:'));
    expect(messages, isNotEmpty);
    expect(
      messages.every((t) => t.contains('+1.1 m') && t.contains('+2 steps')),
      isTrue,
    );

    controller.move(const LatLng(0, .001), 20);
    await tester.pumpAndSettle();
    expect(labels().length, greaterThan(initialCount));
    checkBoundsAndCollisions();
    controller.rotate(35);
    await tester.pumpAndSettle();
    checkBoundsAndCollisions();
    await tester.pumpWidget(map(const Size(360, 240), textScale: 1.5));
    await tester.pumpAndSettle();
    expect(labels().length, lessThan(initialCount));
    checkBoundsAndCollisions();
    controller.move(const LatLng(1, 1), 18);
    await tester.pumpAndSettle();
    expect(labels(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overlapping subsessions share label space and toggling releases it',
    (tester) async {
      final one = fixtures
          .session([for (var i = 0; i < 100; i++) fixtures.gps(i, i * .00001)])
          .copyWith(sourcePath: '/session_one.json');
      final two = one.copyWith(sourcePath: '/session_two.json');
      Widget map(List<Session> sessions) => MaterialApp(
        home: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(0, .0005),
            initialZoom: 18,
          ),
          children: [StepMarkerLayer(sessions: sessions)],
        ),
      );
      int count() => tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers
          .where((m) => m.alignment == Alignment.topCenter)
          .length;
      await tester.pumpWidget(map([one]));
      await tester.pumpAndSettle();
      final singleCount = count();
      await tester.pumpWidget(map([one, two]));
      await tester.pumpAndSettle();
      expect(count(), singleCount);
      await tester.pumpWidget(map([two]));
      await tester.pumpAndSettle();
      expect(count(), singleCount);
      await tester.pumpWidget(map([]));
      await tester.pumpAndSettle();
      expect(count(), 0);
      expect(tester.takeException(), isNull);
    },
  );
}
