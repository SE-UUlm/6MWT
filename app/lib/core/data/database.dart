import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

enum WalkPhase { idle, running, finished, aborted }

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
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get height => integer()();
  IntColumn get age => integer()();
}

@DataClassName('WalkSessionRow')
class WalkSessions extends Table {
  TextColumn get id => text()();

  DateTimeColumn get startedAt => dateTime()();
  IntColumn get duration => integer()(); // In seconds
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
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: '6mwt_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
