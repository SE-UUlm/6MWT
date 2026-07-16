import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// Use SensorSampleRow for generated datatypes so it does not conflict with our SensorSample class
@DataClassName('SensorSampleRow')
// Add index for sessionId because we will always query SensorSamples by sessionId
@TableIndex(name: 'sample_session_id', columns: {#sessionId})
class SensorSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get sessionId => text()();
  TextColumn get type => text()();
  TextColumn get sourceId => text()();
  TextColumn get values => text()(); // Values Map as json
}

@DriftDatabase(tables: [SensorSamples])
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
