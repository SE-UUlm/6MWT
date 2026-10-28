// Entry point for the README screenshots: the real app with an in-memory
// database, a synthetic profile and history, and a simulated walk instead of
// real sensors. SCREEN selects the opened screen; take_screenshots.py builds
// it once per screen.
import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_minute_walk_test/app/app.dart';
import 'package:six_minute_walk_test/app/router.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';

const screen = String.fromEnvironment('SCREEN', defaultValue: 'home');

class _FakeSource extends SensorSource {
  _FakeSource(this.sourceId);

  @override
  final String sourceId;
  final controller = StreamController<SensorSample>.broadcast();

  @override
  Stream<SensorSample> get samples => controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase(NativeDatabase.memory());
  final profileId = await db
      .into(db.profiles)
      .insert(
        ProfilesCompanion.insert(
          name: const Value('Demo'),
          height: 170,
          age: 30,
          gender: Gender.other,
          weight: 65,
        ),
      );
  final profile = await (db.select(
    db.profiles,
  )..where((p) => p.id.equals(profileId))).getSingle();
  final expected = expectedSixMinuteDistance(ageInYears: 30, heightInCm: 170);

  // A test at 14:30 [daysAgo]; a null [percent] is a stopped test.
  final today = DateTime.now();
  WalkSessionRow row(int daysAgo, double? percent) {
    final day = today.subtract(Duration(days: daysAgo));
    return WalkSessionRow(
      id: 'demo-$daysAgo',
      startedAt: DateTime(day.year, day.month, day.day, 14, 30).toUtc(),
      duration: percent == null
          ? const Duration(minutes: 2, seconds: 12)
          : const Duration(minutes: 6),
      distance: percent == null ? 151 : expected * percent / 100,
      distanceConfidence: 0.92,
      phase: percent == null ? WalkPhase.aborted : WalkPhase.finished,
      profileId: profileId,
    );
  }

  final sessions = [
    row(1, 97.3),
    row(4, 94.6),
    row(7, null),
    row(9, 91.2),
    row(13, 88.4),
  ];
  for (final s in sessions) {
    await db.into(db.walkSessions).insert(s);
  }

  var clockOffset = Duration.zero;
  final gps = _FakeSource('gps');
  final steps = _FakeSource(PedometerSource.id);

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      walkSessionProvider.overrideWith((ref) {
        final session = WalkSession(
          sources: [gps],
          optionalSources: [steps],
          distanceEstimator: createPrimaryDistanceEstimator(),
          comparisonEstimators: createComparisonEstimators(),
          now: () => DateTime.now().add(clockOffset),
        );
        ref.onDispose(session.dispose);
        return session;
      }),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SixMinuteWalkApp(locale: Locale('en')),
    ),
  );

  await Future<void>.delayed(const Duration(milliseconds: 300));

  switch (screen) {
    case 'home':
      break;
    case 'instructions':
      router.go('/instructions');
    case 'profile':
      router.go('/profile');
    case 'history':
      router.go('/history');
    case 'result':
      router.go(
        '/result',
        extra: WalkSessionWithProfile(
          session: sessions.first,
          profile: profile,
        ),
      );
    case 'walk':
      final session = container.read(walkSessionProvider);
      session.setProfile(id: profileId, heightCm: 170, gender: 'other');
      router.go('/walk');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await session.start();

      const elapsed = Duration(minutes: 3, seconds: 26);
      final start = session.state.startedAt!;
      clockOffset = elapsed;

      // Walk north-east across the Uni Ulm campus at about 1.5 m/s.
      const lat0 = 48.42131, lon0 = 9.95564;
      const metresPerDegLat = 111320.0;
      final metresPerDegLon = metresPerDegLat * cos(lat0 * pi / 180);
      final random = Random(6);
      for (var t = 1; t <= elapsed.inSeconds; t++) {
        final timestamp = start.add(Duration(seconds: t));
        final d = t * 1.5 + random.nextDouble() * 0.2;
        final heading = 0.68 + 0.05 * sin(t / 40);
        steps.controller.add(
          SensorSample(
            timestamp: timestamp,
            type: SampleType.steps,
            sourceId: PedometerSource.id,
            values: {StepKeys.cumulativeSteps: 1000 + t * 1.85},
          ),
        );
        gps.controller.add(
          SensorSample(
            timestamp: timestamp,
            type: SampleType.position,
            sourceId: 'gps',
            values: {
              PositionKeys.latitude: lat0 + d * cos(heading) / metresPerDegLat,
              PositionKeys.longitude: lon0 + d * sin(heading) / metresPerDegLon,
              PositionKeys.accuracy: 3.0 + random.nextDouble(),
              PositionKeys.altitude: 610,
              PositionKeys.speed: 1.5,
              PositionKeys.heading: heading * 180 / pi,
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);
      }
  }
}
