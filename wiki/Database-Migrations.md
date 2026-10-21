# Database Migrations

Run all commands from `app/`.

1. **Before changing the schema**, ensure the current version has a snapshot in
   `drift_schemas/6mwt_database/`. If missing, run:

   ```sh
   dart run drift_dev make-migrations
   ```

2. **Change the tables** in `lib/core/data/database.dart` and increment
   `schemaVersion`. Regenerate the database code and migration helpers:

   ```sh
   dart run build_runner build
   dart run drift_dev make-migrations
   ```

3. **Implement the upgrade** in `AppDatabase.migration`. Add a `fromXToY` callback
   to `stepByStep`, using the supplied `schema` for that version. Generation only
   creates snapshots and helpers; it does not implement the migration.
   For example, version 1 → 2 uses `TableMigration` to add required `gender` and
   `weight` columns, filling existing profiles with `other` and `0.0`.

4. **Test and commit.** Extend `test/drift/6mwt_database/migration_test.dart`
   with existing rows to check data preservation and any replacement values.

   ```sh
   flutter test test/drift/6mwt_database/migration_test.dart
   flutter test
   ```

   Commit the schema changes, migration, snapshots, generated Dart files and
   tests together. Keep old snapshots unchanged and do not edit generated files
   manually.

Drift upgrades existing databases automatically when opened. Fresh installations
create the latest schema directly.
