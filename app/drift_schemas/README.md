# Database schema snapshots

Versioned Drift schema snapshots used to generate migration helpers and verify upgrades of existing databases. Keep historical snapshots unchanged; do not edit generated files manually.

The `6mwt_database/` directory contains one JSON snapshot per schema version. These describe the database structure, not recorded sessions or participant data.

The current schema and migration implementation live in `lib/core/data/database.dart`, relative to `app/`. When changing the schema, update its version, generate the new snapshot and helpers, and test preservation of existing rows. Generating a snapshot does not implement the upgrade logic.

See [Database Migrations](../../wiki/Database-Migrations.md) for schema changes, generation and migration tests.
