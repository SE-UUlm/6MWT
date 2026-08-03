import 'package:drift/drift.dart';

import 'database.dart';

class WalkSessionRepository {
  WalkSessionRepository(this._db);

  final AppDatabase _db;

  Future<void> saveResult({
    required String id,
    required DateTime startedAt,
    required Duration duration,
    required double distance,
    required WalkPhase phase,
    required int profileId,
  }) {
    return _db
        .into(_db.walkSessions)
        .insertOnConflictUpdate(
          WalkSessionsCompanion.insert(
            id: id,
            startedAt: startedAt,
            duration: duration.inSeconds,
            distance: distance,
            phase: phase,
            profileId: profileId,
          ),
        );
  }

  // Newest first, for the history screen.
  Stream<List<WalkSessionRow>> watchResults() {
    final query = _db.select(_db.walkSessions)
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]);

    return query.watch();
  }
}
