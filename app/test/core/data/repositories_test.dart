import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/sample_repository.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SampleRepository', () {
    SensorSample createSample(DateTime timestamp, double latitude) {
      return SensorSample(
        timestamp: timestamp,
        sourceId: 'gps',
        type: SampleType.position,
        values: {
          PositionKeys.latitude: latitude,
          PositionKeys.longitude: 0,
          PositionKeys.accuracy: 5,
        },
      );
    }

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

      expect(json, contains('"sourceId":"gps"'));
      expect(json, contains('"latitude":48.5'));
    });
  });
}
