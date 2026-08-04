import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';

void main() {
  late AppDatabase db;
  late WalkSessionRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = WalkSessionRepository(db);

    // Insert a profile to satisfy the foreign key constraint.
    await db
        .into(db.profiles)
        .insert(ProfilesCompanion.insert(height: 180, age: 27));
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper that inserts a profile and returns its auto-generated id.
  Future<int> insertProfile({int height = 170, int age = 30}) async {
    return db
        .into(db.profiles)
        .insert(ProfilesCompanion.insert(height: height, age: age));
  }

  test('saves results and lists them newest first', () async {
    await repository.saveSession(
      WalkSessionRow(
        id: 'older',
        startedAt: _july1,
        duration: Duration(minutes: 6),
        distance: 420,
        phase: WalkPhase.finished,
        profileId: 1,
      ),
    );
    await repository.saveSession(
      WalkSessionRow(
        id: 'newer',
        startedAt: _july2,
        duration: Duration(minutes: 2),
        distance: 150,
        phase: WalkPhase.aborted,
        profileId: 1,
      ),
    );

    final results = await repository.watchSessions().first;

    expect(results, hasLength(2));
    // Newest first.
    expect(results.first.id, 'newer');
    expect(results.first.phase, WalkPhase.aborted);
    // Oldest last, verify stored values.
    expect(results.last.id, 'older');
    expect(results.last.distance, 420);
    expect(results.last.duration, const Duration(minutes: 6));
    expect(results.last.phase, WalkPhase.finished);
  });

  test('updates existing session on conflict (same id)', () async {
    await repository.saveSession(
      WalkSessionRow(
        id: 'session-1',
        startedAt: _july1,
        duration: Duration(seconds: 30),
        distance: 50,
        phase: WalkPhase.running,
        profileId: 1,
      ),
    );

    // Same id, but updated distance and phase (simulates periodic save).
    await repository.saveSession(
      WalkSessionRow(
        id: 'session-1',
        startedAt: _july1,
        duration: Duration(minutes: 6),
        distance: 400,
        phase: WalkPhase.finished,
        profileId: 1,
      ),
    );

    final results = await repository.watchSessions().first;

    expect(results, hasLength(1));
    expect(results.single.id, 'session-1');
    expect(results.single.distance, 400);
    expect(results.single.phase, WalkPhase.finished);
  });

  test('stores the correct profileId for each session', () async {
    final profileA = await insertProfile(height: 180, age: 25);
    final profileB = await insertProfile(height: 165, age: 40);

    await repository.saveSession(
      WalkSessionRow(
        id: 'session-a',
        startedAt: _july1,
        duration: const Duration(minutes: 6),
        distance: 500,
        phase: WalkPhase.finished,
        profileId: profileA,
      ),
    );
    await repository.saveSession(
      WalkSessionRow(
        id: 'session-b',
        startedAt: _july2,
        duration: const Duration(minutes: 6),
        distance: 450,
        phase: WalkPhase.finished,
        profileId: profileB,
      ),
    );

    final results = await repository.watchSessions().first;

    expect(results, hasLength(2));
    final sessionB = results.firstWhere((r) => r.id == 'session-b');
    final sessionA = results.firstWhere((r) => r.id == 'session-a');
    expect(sessionA.profileId, profileA);
    expect(sessionB.profileId, profileB);
  });

  test('watchSessions emits updates when a new session is saved', () async {
    // Take 2 emissions: initial (empty) and after the insert.
    final future = repository.watchSessions().take(2).toList();

    // Give the stream time to set up before triggering the insert.
    await Future<void>.delayed(Duration.zero);

    await repository.saveSession(
      WalkSessionRow(
        id: 'live',
        startedAt: _july5,
        duration: Duration(minutes: 6),
        distance: 380,
        phase: WalkPhase.finished,
        profileId: 1,
      ),
    );

    final emissions = await future;

    expect(emissions[0], isEmpty);
    expect(emissions[1], hasLength(1));
    expect(emissions[1].single.id, 'live');
  });

  test('saves zero-distance aborted session correctly', () async {
    await repository.saveSession(
      WalkSessionRow(
        id: 'aborted-early',
        startedAt: _july3,
        duration: Duration(seconds: 5),
        distance: 0,
        phase: WalkPhase.aborted,
        profileId: 1,
      ),
    );

    final results = await repository.watchSessions().first;

    expect(results, hasLength(1));
    expect(results.single.distance, 0);
    expect(results.single.duration, const Duration(seconds: 5));
    expect(results.single.phase, WalkPhase.aborted);
  });
}

// Shared test dates — DateTime can't be const, but top-level finals keep
// the test bodies clean.
final _july1 = DateTime(2026, 7, 1, 10);
final _july2 = DateTime(2026, 7, 2, 10);
final _july3 = DateTime(2026, 7, 3, 8);
final _july5 = DateTime(2026, 7, 5, 12);
