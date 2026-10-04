# Session timestamps to UTC

Converts timestamps in recorded `session.json` files to UTC. Older app versions
saved GPS timestamps in UTC but step timestamps in local time without a timezone.
This made the sensor streams appear shifted when comparing or replaying sessions.
The tool normalizes these older recordings so both streams share the same time basis.

```bash
python3 tools/session_timestamps_to_utc/convert.py
```

Requires Python 3.10+. Directly overwrites all changed `data/**/session.json`
files; no options or backups. Prints the changed folders and assumed UTC offsets.

The offset is inferred from local `startedAt` and the first UTC GPS sample,
rounded to 15 minutes. This assumes both refer to approximately the same time.
Existing UTC timestamps and `reference.json` remain unchanged.
Files without enough information are skipped with an error.
