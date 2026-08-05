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

  test('exports a session as list of maps with decoded values', () async {
    final repository = SampleRepository(db);

    repository.addSample(
      'session-1',
      createSample(DateTime.utc(2026, 7, 1, 12), 48.5),
    );
    await repository.flush();

    final result = await repository.exportSession('session-1');

    expect(result, hasLength(1));
    expect(result.first['sourceId'], 'gps');
    expect(result.first['type'], 'position');
    expect((result.first['values'] as Map<String, dynamic>)['latitude'], 48.5);
    expect(result.first['timestamp'], isA<String>());
    expect(result.first['id'], isA<int>());
  });

  test('exportSession returns samples ordered by timestamp', () async {
    final repository = SampleRepository(db);

    final t1 = DateTime.utc(2026, 7, 1, 12, 0, 0);
    final t2 = DateTime.utc(2026, 7, 1, 12, 0, 1);
    final t3 = DateTime.utc(2026, 7, 1, 12, 0, 2);

    // Insert out of order.
    repository.addSample('session-1', createSample(t3, 3));
    repository.addSample('session-1', createSample(t1, 1));
    repository.addSample('session-1', createSample(t2, 2));
    await repository.flush();

    final result = await repository.exportSession('session-1');

    expect(result, hasLength(3));
    expect((result[0]['values'] as Map<String, dynamic>)['latitude'], 1);
    expect((result[1]['values'] as Map<String, dynamic>)['latitude'], 2);
    expect((result[2]['values'] as Map<String, dynamic>)['latitude'], 3);
  });

  test('exportSession returns empty list for unknown session', () async {
    final repository = SampleRepository(db);

    final result = await repository.exportSession('nonexistent');

    expect(result, isEmpty);
  });

  test('exportAllSessions groups samples by sessionId', () async {
    final repository = SampleRepository(db);

    repository.addSample(
      'session-1',
      createSample(DateTime.utc(2026, 7, 1, 12), 1),
    );
    repository.addSample(
      'session-1',
      createSample(DateTime.utc(2026, 7, 1, 12, 0, 1), 2),
    );
    repository.addSample(
      'session-2',
      createSample(DateTime.utc(2026, 7, 2, 10), 10),
    );
    await repository.flush();

    final grouped = await repository.exportAllSessions();

    expect(grouped.keys, containsAll(['session-1', 'session-2']));
    expect(grouped['session-1'], hasLength(2));
    expect(grouped['session-2'], hasLength(1));
    expect((grouped['session-2']!.first['values'] as Map)['latitude'], 10);
  });

  test('exportAllSessions returns empty map when no samples exist', () async {
    final repository = SampleRepository(db);

    final grouped = await repository.exportAllSessions();

    expect(grouped, isEmpty);
  });
}
