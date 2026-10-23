import 'package:drift/drift.dart';

import '../../app/log.dart';
import 'database.dart';

final _log = appLogger('WalkSessionRepository');

/// A history entry with the profile that was active during the walk session.
class WalkSessionWithProfile {
  const WalkSessionWithProfile({required this.session, required this.profile});

  final WalkSessionRow session;
  final Profile profile;
}

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

  /// Watches sessions and their associated profiles, newest session first.
  Stream<List<WalkSessionWithProfile>> watchSessionsWithProfiles() {
    final query = _db.select(_db.walkSessions).join([
      innerJoin(
        _db.profiles,
        _db.profiles.id.equalsExp(_db.walkSessions.profileId),
      ),
    ])..orderBy([OrderingTerm.desc(_db.walkSessions.startedAt)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          WalkSessionWithProfile(
            session: row.readTable(_db.walkSessions),
            profile: row.readTable(_db.profiles),
          ),
      ],
    );
  }

  static Map<String, dynamic> _rowToMap(WalkSessionRow row) => {
    'id': row.id,
    // Normalize old recordings as well as new UTC session starts.
    'startedAt': row.startedAt.toUtc().toIso8601String(),
    'duration': row.duration.inSeconds,
    'distance': row.distance,
    'distanceConfidence': row.distanceConfidence,
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

  /// Deletes a session and its associated sensor samples atomically.
  /// If the associated profile is not used by any other session, it is also cleaned up.
  Future<void> deleteSession(String sessionId) async {
    await _db.transaction(() async {
      final session = await (_db.select(
        _db.walkSessions,
      )..where((row) => row.id.equals(sessionId))).getSingleOrNull();

      if (session == null) {
        _log.w('Cannot delete session $sessionId: not found');
        return;
      }

      final profileId = session.profileId;

      // Delete associated sensor samples
      await (_db.delete(
        _db.sensorSamples,
      )..where((row) => row.sessionId.equals(sessionId))).go();

      // Delete walk session row
      await (_db.delete(
        _db.walkSessions,
      )..where((row) => row.id.equals(sessionId))).go();

      // Keep shared profiles, clean up unreferenced profiles
      final remainingWithProfile = await (_db.select(
        _db.walkSessions,
      )..where((row) => row.profileId.equals(profileId))).get();

      if (remainingWithProfile.isEmpty) {
        await (_db.delete(
          _db.profiles,
        )..where((row) => row.id.equals(profileId))).go();
        _log.i('Deleted profile $profileId: no sessions reference it anymore');
      }

      _log.i('Deleted session $sessionId');
    });
  }
}
