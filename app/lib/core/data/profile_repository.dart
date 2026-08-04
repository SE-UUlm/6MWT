import 'package:drift/drift.dart';

import 'database.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  Future<Profile?> loadProfile(int profileId) {
    final query = _db.select(_db.profiles)
      ..where((row) => row.id.equals(profileId));

    return query.getSingleOrNull();
  }

  /// Creates a new profile with the provided details and returns the profile Id.
  /// Or if the same profile already exists, it is reused
  Future<int> ensureProfile({
    String? name,
    required int height,
    required int age,
  }) async {
    // Look for an existing profile with the same name, height, and age.
    final query = _db.select(_db.profiles)
      ..where(
        (row) =>
            row.name.equalsNullable(name) &
            row.height.equals(height) &
            row.age.equals(age),
      );

    final existing = await query.get();
    if (existing.isNotEmpty) {
      return existing.first.id;
    }

    // No matching profile found – create a new one.
    return _db
        .into(_db.profiles)
        .insert(
          ProfilesCompanion.insert(height: height, age: age, name: Value(name)),
        );
  }
}
