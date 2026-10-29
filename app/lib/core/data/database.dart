import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/log.dart';
import 'database.steps.dart';
import '../domain/walk_phase.dart';

part 'database.drift.dart';

final _log = appLogger('AppDatabase');

enum Gender { male, female, other }

class DurationConverter extends TypeConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromSql(int fromDb) => Duration(seconds: fromDb);

  @override
  int toSql(Duration value) => value.inSeconds;
}

// Use SensorSampleRow for generated datatypes so it does not conflict with our SensorSample class
@DataClassName('SensorSampleRow')
// Add index for sessionId because we will always query SensorSamples by sessionId
@TableIndex(name: 'sample_session_id', columns: {#sessionId})
class SensorSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get sessionId => text().references(WalkSessions, #id)();
  TextColumn get type => text()();
  TextColumn get sourceId => text()();
  TextColumn get values => text()(); // Values Map as json
}

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().nullable()();
  // SQLite generates this timestamp in UTC; Drift reads the text value as UTC.
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get height => integer()();
  IntColumn get age => integer()();
  TextColumn get gender => textEnum<Gender>()();
  RealColumn get weight => real()();
}

@DataClassName('WalkSessionRow')
class WalkSessions extends Table {
  TextColumn get id => text()();

  DateTimeColumn get startedAt => dateTime()();
  Column<int> get duration => integer().map(const DurationConverter())();
  RealColumn get distance => real()(); // In meters
  // Heuristic 0..1 score of the primary estimator; null for older sessions.
  RealColumn get distanceConfidence => real().nullable()();

  TextColumn get phase => textEnum<WalkPhase>()();

  IntColumn get profileId => integer().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [SensorSamples, Profiles, WalkSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      if (details.wasCreated) {
        _log.i('Database created (schema ${details.versionNow})');
      } else if (details.hadUpgrade) {
        _log.i(
          'Database upgraded from schema ${details.versionBefore} '
          'to ${details.versionNow}',
        );
      } else {
        _log.d('Database opened (schema ${details.versionNow})');
      }
      await customStatement('PRAGMA foreign_keys = ON');
      final orphans = await customUpdate(
        'DELETE FROM sensor_samples WHERE session_id NOT IN (SELECT id FROM walk_sessions);',
        updates: {sensorSamples},
        updateKind: UpdateKind.delete,
      );
      if (orphans > 0) {
        _log.w('Removed $orphans orphaned sensor samples');
      }
    },
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        _log.i('Migrating database from schema 1 to 2');
        // Backfill old test profiles only. New profiles must supply both values.
        // Rebuilding the table keeps schema 2 free of permanent SQL defaults.
        await m.alterTable(
          TableMigration(
            schema.profiles,
            newColumns: [schema.profiles.gender, schema.profiles.weight],
            columnTransformer: {
              schema.profiles.gender: const Constant('other'),
              schema.profiles.weight: const Constant(0.0),
            },
          ),
        );
      },
      from2To3: (m, schema) async {
        _log.i('Migrating database from schema 2 to 3');
        // Existing sessions keep no stored confidence; it is recomputed on display.
        await m.addColumn(
          schema.walkSessions,
          schema.walkSessions.distanceConfidence,
        );
      },
    ),
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: '6mwt_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
