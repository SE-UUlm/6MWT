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

  static Map<String, dynamic> _rowToMap(WalkSessionRow row) => {
    'id': row.id,
    'startedAt': row.startedAt.toIso8601String(),
    'duration': row.duration.inSeconds,
    'distance': row.distance,
    'phase': row.phase.name,
    'profileId': row.profileId,
  };

  Future<Map<String, dynamic>?> exportSession(String sessionId) async {
    final query = _db.select(_db.walkSessions)
      ..where((row) => row.id.equals(sessionId));

    final row = await query.getSingleOrNull();
    return row == null ? null : _rowToMap(row);
  }

  Future<List<Map<String, dynamic>>> exportAllSessions() async {
    final rows = await _db.select(_db.walkSessions).get();
    return [for (final row in rows) _rowToMap(row)];
  }
}
