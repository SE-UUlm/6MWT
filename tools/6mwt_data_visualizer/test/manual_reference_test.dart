import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/core/domain/manual_reference.dart';
import 'package:six_mwt_visualizer/core/domain/session.dart';
import 'package:six_mwt_visualizer/features/chart/session_chart_data.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';
import 'package:six_mwt_visualizer/providers/providers.dart';

import 'estimator_replay_test.dart' as fixtures;

void main() {
  final session = fixtures.session([
    fixtures.gps(0, 0),
    fixtures.gps(30, 0.003),
  ]);
  final route = [
    const LatLng(0, 0),
    const LatLng(0, 0.001),
    const LatLng(0, 0.003),
  ];

  test(
    'manual geometry gets distance-proportional timing, no invented steps',
    () {
      final reference = createManualReference(session, route, '  My route  ');
      expect(reference.referenceName, 'My route');
      expect(reference.distance, closeTo(333.58, 0.1));
      expect(
        reference.samples[1].timestamp.difference(fixtures.start).inSeconds,
        10,
      );
      expect(reference.samples.last.timestamp, session.sessionEndUtc);
      expect(reference.stepSamples, isEmpty);
      final decoded = Session.fromJson(reference.toReferenceJson());
      expect(decoded.isManualReference, isTrue);
      expect(decoded.referenceName, reference.referenceName);
      expect(decoded.distance, reference.distance);
      expect(decoded.samples.last.values['distance'], reference.distance);
    },
  );

  test('invalid routes cannot be saved as a meaningful reference', () {
    for (final points in [
      <LatLng>[],
      [route.first],
      [route.first, route.first],
    ]) {
      expect(
        () => createManualReference(session, points, 'Route'),
        throwsArgumentError,
      );
    }
    expect(
      () => createManualReference(session, route, ' '),
      throwsArgumentError,
    );
    expect(
      () => createManualReference(
        fixtures.session([fixtures.gps(0, 0)]),
        route,
        'Route',
      ),
      throwsArgumentError,
    );
  });

  test(
    'save twice and reload preserves all references and source files',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'visualizer-references-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final source = File('${folder.path}/session.json');
      final legacy = File('${folder.path}/reference.json');
      final sourceText = jsonEncode(session.toReferenceJson());
      final legacyText = jsonEncode(
        fixtures.session([
          fixtures.gps(0, 0, distance: 0),
          fixtures.gps(30, 0.002, distance: 200),
        ]).toReferenceJson(),
      );
      await source.writeAsString(sourceText);
      await legacy.writeAsString(legacyText);
      await File(
        '${folder.path}/reference_broken.json',
      ).writeAsString('{broken');
      var loaded = (await SessionLoader.load(source.path)).sessions.single;
      expect(loaded.references, hasLength(1));
      for (final name in ['Route A', 'Route B']) {
        loaded = await SessionLoader.saveReference(
          loaded,
          createManualReference(loaded, route, name),
        );
      }
      final reloaded = (await SessionLoader.load(folder.path)).sessions.single;
      expect(reloaded.references, hasLength(3));
      expect(reloaded.references.skip(1).map((r) => r.referenceName), [
        'Route A',
        'Route B',
      ]);
      expect(
        reloaded.references.skip(1).every((r) => r.isManualReference),
        isTrue,
      );
      expect(await source.readAsString(), sourceText);
      expect(await legacy.readAsString(), legacyText);
      expect(
        (await Directory('${folder.path}/references').list().toList()),
        hasLength(2),
      );
    },
  );

  test(
    'legacy multi-session exports keep saved routes with their session',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'visualizer-export-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}/export.json');
      final second = {...session.toReferenceJson(), 'id': 'second/session'};
      await file.writeAsString(
        jsonEncode({
          'sessions': [session.toReferenceJson(), second],
        }),
      );
      final data = await SessionLoader.load(file.path);
      await SessionLoader.saveReference(
        data.sessions.last,
        createManualReference(data.sessions.last, route, 'Other session'),
      );
      final loaded = await SessionLoader.load(file.path);
      expect(loaded.sessions.first.references, isEmpty);
      expect(
        loaded.sessions.last.references.single.referenceName,
        'Other session',
      );
    },
  );

  test('chart and replay retain every reference with independent overlap', () {
    final partial = fixtures.session([
      fixtures.gps(5, 0, distance: 10),
      fixtures.gps(25, 0.001, distance: 90),
    ]);
    final manual = createManualReference(session, route, 'Route');
    final combined = session.copyWith(references: [partial, manual]);
    final chart = SessionChartData.fromSession(combined);
    expect(chart.referenceSeries, hasLength(2));
    expect(
      chart.referenceSeries.last.gps.last.y,
      closeTo(manual.distance, 0.001),
    );
    expect(chart.referenceSeries.last.label, contains('constant speed'));
    final replay = EstimatorReplay(combined);
    expect(replay.references, hasLength(2));
    expect(replay.references.first.points!.first.seconds, 5);
    expect(replay.references.first.points!.last.meters, 80);
    expect(replay.references.last.points!.first.seconds, 0);
    expect(replay.references.last.points!.last.seconds, 30);
    expect(
      replay.references.last.points!.last.meters,
      closeTo(manual.distance, 0.001),
    );
    expect(replay.samples, hasLength(session.samples.length));
  });

  test(
    'saving updates list and selected session without losing other sessions',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'visualizer-provider-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}/session.json');
      await file.writeAsString(jsonEncode(session.toReferenceJson()));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dataSub = container.listen(exportDataProvider, (_, _) {});
      final selectedSub = container.listen(selectedSessionProvider, (_, _) {});
      addTearDown(dataSub.close);
      addTearDown(selectedSub.close);
      final notifier = container.read(exportDataProvider.notifier);
      await notifier.loadFromPath(file.path);
      final original = container
          .read(exportDataProvider)
          .requireValue!
          .sessions
          .single;
      container.read(selectedSessionProvider.notifier).select(original);
      final updated = await SessionLoader.saveReference(
        original,
        createManualReference(original, route, 'New route'),
      );
      notifier.replaceSession(original, updated);
      expect(container.read(selectedSessionProvider), same(updated));
      expect(
        container.read(exportDataProvider).requireValue!.sessions.single,
        same(updated),
      );
    },
  );
}
