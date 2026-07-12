import 'package:drift/drift.dart';

import 'database.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  static const _profileId = 1;

  final AppDatabase _db;

  Future<Profile?> loadProfile() {
    final query = _db.select(_db.profiles)
      ..where((row) => row.id.equals(_profileId));

    return query.getSingleOrNull();
  }

  Future<void> saveProfile({
    double? weightKg,
    double? heightCm,
    int? birthYear,
    String? sex,
  }) {
    return _db
        .into(_db.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: const Value(_profileId),
            weightKg: Value(weightKg),
            heightCm: Value(heightCm),
            birthYear: Value(birthYear),
            sex: Value(sex),
          ),
        );
  }
}
