// dart format width=80
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            addTearDown(db.close);
            await verifier.migrateAndValidate(db, toVersion);
          });
        }
      });
    }
  });

  test('migration from v1 to v2 does not corrupt data', () async {
    final oldProfilesData = <v1.ProfilesData>[
      v1.ProfilesData(
        id: 7,
        name: 'Testprofil',
        timestamp: '2026-10-15T10:30:00.000Z',
        height: 175,
        age: 42,
      ),
      v1.ProfilesData(
        id: 8,
        timestamp: '2026-10-15T11:30:00.000Z',
        height: 165,
        age: 35,
      ),
    ];
    final expectedNewProfilesData = [
      for (final row in oldProfilesData)
        v2.ProfilesData.fromJson({
          ...row.toJson(),
          'gender': 'other',
          'weight': 0.0,
        }),
    ];

    final oldWalkSessionsData = <v1.WalkSessionsData>[
      v1.WalkSessionsData(
        id: 'session-1',
        startedAt: '2026-10-15T10:35:00.000Z',
        duration: 360,
        distance: 512.5,
        phase: 'finished',
        profileId: 7,
      ),
    ];
    final expectedNewWalkSessionsData = [
      for (final row in oldWalkSessionsData)
        v2.WalkSessionsData.fromJson(row.toJson()),
    ];

    final oldSensorSamplesData = <v1.SensorSamplesData>[
      v1.SensorSamplesData(
        id: 11,
        timestamp: '2026-10-15T10:35:01.123456Z',
        sessionId: 'session-1',
        type: 'gps',
        sourceId: 'phone',
        values: '{"latitude":52.5}',
      ),
    ];
    final expectedNewSensorSamplesData = [
      for (final row in oldSensorSamplesData)
        v2.SensorSamplesData.fromJson(row.toJson()),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.profiles, oldProfilesData);
        batch.insertAll(oldDb.walkSessions, oldWalkSessionsData);
        batch.insertAll(oldDb.sensorSamples, oldSensorSamplesData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewProfilesData,
          await newDb.select(newDb.profiles).get(),
        );
        expect(
          expectedNewWalkSessionsData,
          await newDb.select(newDb.walkSessions).get(),
        );
        expect(
          expectedNewSensorSamplesData,
          await newDb.select(newDb.sensorSamples).get(),
        );
        expect(
          await newDb.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        final newId = await newDb
            .into(newDb.profiles)
            .insert(
              v2.ProfilesCompanion.insert(
                height: 180,
                age: 30,
                gender: 'female',
                weight: 70,
              ),
            );
        expect(newId, greaterThan(8));
        final inserted = await (newDb.select(
          newDb.profiles,
        )..where((row) => row.id.equals(newId))).getSingle();
        expect(inserted.gender, 'female');
        expect(inserted.weight, 70);
      },
    );
  });

  test(
    'fresh installation creates schema 2 and stores supplied values',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              height: 175,
              age: 42,
              gender: Gender.male,
              weight: 75,
            ),
          );
      final profile = await db.select(db.profiles).getSingle();
      expect(profile.gender, Gender.male);
      expect(profile.weight, 75);
    },
  );
}
