# Session timestamps to UTC

Normalize older recordings whose step timestamps use local time while GPS uses UTC.

This repairs apparent time shifts between sensor streams during visualization and replay. The script scans `data/**/session.json`, estimates the missing timezone offset from the session start and the first UTC GPS sample, and writes timestamps in UTC. It requires Python 3.10+.

Run from the repository root:

```sh
python3 tools/session_timestamps_to_utc/convert.py
```

**Overwrites changed `data/**/session.json` files without backups.** Review the [assumptions and usage](../../wiki/Data-and-Tools.md#timestamp-converter) first.

Back up recordings before running it and inspect the changes afterward. Existing UTC timestamps and reference files remain unchanged; files without enough information are skipped with an error. It does not automatically process other filenames such as `session_phone.json`.
