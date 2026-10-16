import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'database.steps.dart';

part 'database.drift.dart';

enum WalkPhase { idle, running, finished, aborted }

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

  TextColumn get phase => textEnum<WalkPhase>()();

  IntColumn get profileId => integer().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [SensorSamples, Profiles, WalkSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
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
