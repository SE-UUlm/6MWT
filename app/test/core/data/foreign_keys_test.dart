import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('PRAGMA foreign_keys is enabled on opened connection', () async {
    final result = await db.customSelect('PRAGMA foreign_keys;').getSingle();
    expect(result.data['foreign_keys'], 1);
  });

  test(
    'fails when inserting a walk session with non-existent profileId',
    () async {
      expect(
        () => db
            .into(db.walkSessions)
            .insert(
              WalkSessionsCompanion.insert(
                id: 'test-session',
                startedAt: DateTime.utc(2026, 7, 1),
                duration: const Duration(minutes: 6),
                distance: 100,
                phase: WalkPhase.finished,
                profileId: 9999, // Does not exist
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test(
    'fails when inserting a sensor sample with non-existent sessionId',
    () async {
      expect(
        () => db
            .into(db.sensorSamples)
            .insert(
              SensorSamplesCompanion.insert(
                sessionId: 'non-existent-session',
                timestamp: DateTime.utc(2026, 7, 1),
                sourceId: 'gps',
                type: 'position',
                values: '{}',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test('cleans up orphaned sensor samples', () async {
    // Disable foreign keys temporarily on this isolated in-memory test database
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    await db.customStatement('''
      INSERT INTO sensor_samples (timestamp, session_id, type, source_id, "values")
      VALUES ('2026-07-01T12:00:00Z', 'orphan-session', 'position', 'gps', '{}');
    ''');

    final count = await db
        .customSelect('SELECT COUNT(*) as c FROM sensor_samples;')
        .getSingle();
    expect(count.data['c'], 1);

    // Run the cleanup query (same query as in beforeOpen)
    await db.customStatement(
      'DELETE FROM sensor_samples WHERE session_id NOT IN (SELECT id FROM walk_sessions);',
    );

    final remaining = await db.select(db.sensorSamples).get();
    expect(remaining, isEmpty);
  });
}
