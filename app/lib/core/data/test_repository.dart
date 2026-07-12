import 'package:drift/drift.dart';

import 'database.dart';

class TestRepository {
  TestRepository(this._db);

  final AppDatabase _db;

  Future<void> saveResult({
    required String id,
    required DateTime startedAt,
    required Duration duration,
    required double distanceMeters,
    required bool completed,
  }) {
    return _db
        .into(_db.testResults)
        .insertOnConflictUpdate(
          TestResultsCompanion.insert(
            id: id,
            startedAt: startedAt,
            durationSeconds: duration.inSeconds,
            distanceMeters: distanceMeters,
            completed: completed,
          ),
        );
  }

  // Newest first, for the history screen.
  Stream<List<TestResult>> watchResults() {
    final query = _db.select(_db.testResults)
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]);

    return query.watch();
  }
}
