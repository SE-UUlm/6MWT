import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/profile_repository.dart';
import 'package:six_minute_walk_test/core/data/sample_repository.dart';
import 'package:six_minute_walk_test/core/data/test_repository.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TestRepository', () {
    test('saves results and lists them newest first', () async {
      final repository = TestRepository(db);

      await repository.saveResult(
        id: 'older',
        startedAt: DateTime(2026, 7, 1, 10),
        duration: const Duration(minutes: 6),
        distanceMeters: 420,
        completed: true,
      );
      await repository.saveResult(
        id: 'newer',
        startedAt: DateTime(2026, 7, 2, 10),
        duration: const Duration(minutes: 2),
        distanceMeters: 150,
        completed: false,
      );

      final results = await repository.watchResults().first;

      expect(results, hasLength(2));
      expect(results.first.id, 'newer');
      expect(results.first.completed, isFalse);
      expect(results.last.distanceMeters, 420);
      expect(results.last.durationSeconds, 360);
    });
  });

  group('ProfileRepository', () {
    test('returns null when no profile was saved yet', () async {
      final repository = ProfileRepository(db);

      expect(await repository.loadProfile(), isNull);
    });

    test('saves and overwrites the single profile', () async {
      final repository = ProfileRepository(db);

      await repository.saveProfile(
        weightKg: 80,
        heightCm: 180,
        birthYear: 1990,
        sex: 'male',
      );
      await repository.saveProfile(
        weightKg: 78.5,
        heightCm: 180,
        birthYear: 1990,
        sex: 'male',
      );

      final profile = await repository.loadProfile();

      expect(profile, isNotNull);
      expect(profile!.weightKg, 78.5);
      expect(profile.birthYear, 1990);
    });
  });

  group('SampleRepository', () {
    SensorSample createSample(DateTime timestamp, double latitude) {
      return SensorSample(
        timestamp: timestamp,
        sensorId: 'gps',
        type: SampleTypes.position,
        values: {
          PositionKeys.latitude: latitude,
          PositionKeys.longitude: 0,
          PositionKeys.accuracy: 5,
        },
      );
    }

    test('records samples and summarizes them per session', () async {
      final repository = SampleRepository(db);

      repository.addSample('session-1', createSample(DateTime(2026, 7, 1), 1));
      repository.addSample('session-1', createSample(DateTime(2026, 7, 1), 2));
      repository.addSample('session-2', createSample(DateTime(2026, 7, 2), 3));

      // Samples are buffered; flush writes them to the database.
      await repository.flush();

      final recordings = await repository.watchRecordings().first;

      expect(recordings, hasLength(2));
      expect(recordings.first.sessionId, 'session-2');
      expect(recordings.first.sampleCount, 1);
      expect(recordings.last.sessionId, 'session-1');
      expect(recordings.last.sampleCount, 2);
    });

    test('exports a session as CSV with one column per value key', () async {
      final repository = SampleRepository(db);

      repository.addSample(
        'session-1',
        createSample(DateTime.utc(2026, 7, 1, 12), 48.5),
      );
      await repository.flush();

      final csv = await repository.exportSessionAsCsv('session-1');
      final lines = csv.trim().split('\n');

      expect(lines, hasLength(2));
      expect(lines.first, 'timestamp,sensor_id,sample_type,accuracy,latitude,longitude');
      expect(lines.last, contains('gps,position'));
      expect(lines.last, contains('48.5'));
    });

    test('writes a full buffer to the database on its own', () async {
      final repository = SampleRepository(db);

      for (var i = 0; i < 100; i++) {
        repository.addSample(
          'session-1',
          createSample(DateTime(2026, 7, 1).add(Duration(seconds: i)), 1),
        );
      }

      // The 100th sample triggers an automatic batch insert — no flush call.
      await Future<void>.delayed(Duration.zero);

      final rows = await db.select(db.sensorSamples).get();
      expect(rows, hasLength(100));
    });

    test('exports a session as JSON with decoded values', () async {
      final repository = SampleRepository(db);

      repository.addSample(
        'session-1',
        createSample(DateTime.utc(2026, 7, 1, 12), 48.5),
      );
      await repository.flush();

      final json = await repository.exportSessionAsJson('session-1');

      expect(json, contains('"sensorId": "gps"'));
      expect(json, contains('"latitude": 48.5'));
    });
  });
}
