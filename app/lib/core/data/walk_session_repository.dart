import 'package:drift/drift.dart';

import 'database.dart';

class WalkSessionRepository {
  WalkSessionRepository(this._db);

  final AppDatabase _db;

  Future<void> saveSession(WalkSessionRow session) {
    return _db.into(_db.walkSessions).insertOnConflictUpdate(session);
  }

  // Newest first, for the history screen.
  Stream<List<WalkSessionRow>> watchSessions() {
    final query = _db.select(_db.walkSessions)
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]);

    return query.watch();
  }
}
