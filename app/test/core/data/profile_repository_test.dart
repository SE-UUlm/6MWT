import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/profile_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('returns null when no profile was saved yet', () async {
    final repository = ProfileRepository(db);

    expect(await repository.loadProfile(0), isNull);
  });

  group('ensureProfile', () {
    test('creates a new profile and returns its id', () async {
      final repository = ProfileRepository(db);

      final id = await repository.ensureProfile(
        name: 'Alice',
        height: 170,
        age: 30,
      );

      expect(id, isPositive);

      final profile = await repository.loadProfile(id);
      expect(profile, isNotNull);
      expect(profile!.name, 'Alice');
      expect(profile.height, 170);
      expect(profile.age, 30);
    });

    test(
      'returns existing id when profile with same name, height and age exists',
      () async {
        final repository = ProfileRepository(db);

        final firstId = await repository.ensureProfile(
          name: 'Bob',
          height: 180,
          age: 25,
        );
        final secondId = await repository.ensureProfile(
          name: 'Bob',
          height: 180,
          age: 25,
        );

        expect(secondId, equals(firstId));
      },
    );

    test('creates separate profiles when name differs', () async {
      final repository = ProfileRepository(db);

      final id1 = await repository.ensureProfile(
        name: 'Alice',
        height: 170,
        age: 30,
      );
      final id2 = await repository.ensureProfile(
        name: 'Bob',
        height: 170,
        age: 30,
      );

      expect(id1, isNot(equals(id2)));
    });

    test('creates separate profiles when height differs', () async {
      final repository = ProfileRepository(db);

      final id1 = await repository.ensureProfile(
        name: 'Alice',
        height: 170,
        age: 30,
      );
      final id2 = await repository.ensureProfile(
        name: 'Alice',
        height: 175,
        age: 30,
      );

      expect(id1, isNot(equals(id2)));
    });

    test('creates separate profiles when age differs', () async {
      final repository = ProfileRepository(db);

      final id1 = await repository.ensureProfile(
        name: 'Alice',
        height: 170,
        age: 30,
      );
      final id2 = await repository.ensureProfile(
        name: 'Alice',
        height: 170,
        age: 31,
      );

      expect(id1, isNot(equals(id2)));
    });

    test('handles null name correctly and deduplicates', () async {
      final repository = ProfileRepository(db);

      final id1 = await repository.ensureProfile(height: 165, age: 40);
      final id2 = await repository.ensureProfile(height: 165, age: 40);

      expect(id1, equals(id2));

      final profile = await repository.loadProfile(id1);
      expect(profile, isNotNull);
      expect(profile!.name, isNull);
    });

    test(
      'null name and non-null name are treated as different profiles',
      () async {
        final repository = ProfileRepository(db);

        final idWithoutName = await repository.ensureProfile(
          height: 170,
          age: 30,
        );
        final idWithName = await repository.ensureProfile(
          name: 'Alice',
          height: 170,
          age: 30,
        );

        expect(idWithoutName, isNot(equals(idWithName)));
      },
    );

    test('does not create duplicate rows in the database', () async {
      final repository = ProfileRepository(db);

      await repository.ensureProfile(name: 'Eve', height: 160, age: 22);
      await repository.ensureProfile(name: 'Eve', height: 160, age: 22);
      await repository.ensureProfile(name: 'Eve', height: 160, age: 22);

      final allRows = await db.select(db.profiles).get();
      expect(allRows, hasLength(1));
    });

    test('automatically sets timestamp via database default', () async {
      final repository = ProfileRepository(db);
      final before = DateTime.now();

      final id = await repository.ensureProfile(
        name: 'Timo',
        height: 182,
        age: 27,
      );

      final after = DateTime.now();
      final profile = await repository.loadProfile(id);

      expect(profile, isNotNull);
      expect(profile!.timestamp, isNotNull);
      // The database-generated timestamp should be roughly "now".
      expect(
        profile.timestamp.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch - 1000),
      );
      expect(
        profile.timestamp.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch + 1000),
      );
    });
  });

  group('exportAllProfiles', () {
    test('returns all profiles with correct fields', () async {
      final repository = ProfileRepository(db);

      await repository.ensureProfile(name: 'Alice', height: 170, age: 30);
      await repository.ensureProfile(name: 'Bob', height: 185, age: 25);

      final result = await repository.exportAllProfiles();

      expect(result, hasLength(2));

      final alice = result.firstWhere((m) => m['name'] == 'Alice');
      expect(alice['height'], 170);
      expect(alice['age'], 30);
      expect(alice['id'], isA<int>());
      expect(alice['timestamp'], isA<String>());

      final bob = result.firstWhere((m) => m['name'] == 'Bob');
      expect(bob['height'], 185);
      expect(bob['age'], 25);
    });

    test('handles null name in exported map', () async {
      final repository = ProfileRepository(db);

      await repository.ensureProfile(height: 175, age: 35);

      final result = await repository.exportAllProfiles();

      expect(result, hasLength(1));
      expect(result.first['name'], isNull);
      expect(result.first['height'], 175);
    });

    test('returns empty list when no profiles exist', () async {
      final repository = ProfileRepository(db);

      final result = await repository.exportAllProfiles();

      expect(result, isEmpty);
    });
  });

  group('exportProfile', () {
    test('returns a map with correct fields for existing profile', () async {
      final repository = ProfileRepository(db);

      final id = await repository.ensureProfile(
        name: 'Clara',
        height: 168,
        age: 29,
      );

      final result = await repository.exportProfile(id);

      expect(result, isNotNull);
      expect(result!['id'], id);
      expect(result['name'], 'Clara');
      expect(result['height'], 168);
      expect(result['age'], 29);
      expect(result['timestamp'], isA<String>());
    });

    test('returns null for unknown profile id', () async {
      final repository = ProfileRepository(db);

      final result = await repository.exportProfile(9999);

      expect(result, isNull);
    });
  });
}
