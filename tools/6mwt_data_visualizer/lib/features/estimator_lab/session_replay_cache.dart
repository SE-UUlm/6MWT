import 'package:flutter/foundation.dart';

import '../../core/domain/session.dart';
import 'estimator_replay.dart';
import 'estimators.dart';

class SessionReplayResult {
  const SessionReplayResult(this.replays, this.runs);
  final List<EstimatorReplay> replays;
  final List<List<ReplayResult>> runs;
}

/// Runs outside the UI isolate. Every estimator still sees every sensor sample.
SessionReplayResult runSessionReplay(Session session) {
  final replays = session.recordings.map(EstimatorReplay.new).toList();
  final runs = [
    for (final replay in replays) createEstimators().map(replay.run).toList(),
  ];
  return SessionReplayResult(replays, runs);
}

typedef ReplayLoader = Future<SessionReplayResult> Function(Session session);

/// Weak session keys release results when the loaded dataset is discarded.
/// Replaced/reloaded sessions have new identities and therefore fresh results.
class SessionReplayCache {
  SessionReplayCache({ReplayLoader? loader})
    : _loader = loader ?? _backgroundReplay;
  final ReplayLoader _loader;
  final _entries = Expando<Future<SessionReplayResult>>();

  Future<SessionReplayResult> load(Session session) {
    final existing = _entries[session];
    if (existing != null) return existing;
    final pending = _load(session);
    _entries[session] = pending;
    return pending;
  }

  Future<SessionReplayResult> _load(Session session) async {
    try {
      return await Future.sync(() => _loader(session));
    } catch (_) {
      _entries[session] = null;
      rethrow;
    }
  }
}

Future<SessionReplayResult> _backgroundReplay(Session session) =>
    compute(runSessionReplay, session, debugLabel: 'Estimator Lab replay');

final sessionReplayCache = SessionReplayCache();
