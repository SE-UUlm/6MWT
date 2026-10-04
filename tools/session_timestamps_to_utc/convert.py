#!/usr/bin/env python3
"""Normalize session.json timestamps using the recording's inferred UTC offset."""

import json
import math
from pathlib import Path
from datetime import datetime, timedelta, timezone


TIMESTAMP_KEYS = {"timestamp", "startedAt", "exportedAt"}
DATA_DIR = Path(__file__).resolve().parents[2] / "data"


def parse_timestamp(value):
    if not isinstance(value, str) or "T" not in value:
        raise ValueError(f"Invalid timestamp: {value!r}")
    # Support Python 3.10, whose fromisoformat does not accept a trailing Z.
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def infer_offset(session):
    """Match the visualizer: local session start minus earliest UTC GPS fix.

    Round to quarter hours so small GPS acquisition delays do not become part
    of the timezone offset. No host timezone is used anywhere in this script.
    """
    started_at = parse_timestamp(session.get("startedAt"))
    if started_at.tzinfo is not None:
        raise ValueError("Cannot infer local offset: startedAt is not local")

    gps_times = []
    for sample in session.get("samples", []):
        if sample.get("type") != "position":
            continue
        timestamp = parse_timestamp(sample.get("timestamp"))
        if timestamp.utcoffset() == timedelta(0):
            gps_times.append(timestamp)
    if not gps_times:
        raise ValueError("Cannot infer local offset: no UTC GPS samples")

    difference = (started_at.replace(tzinfo=timezone.utc) - min(gps_times)).total_seconds()
    quarters = difference / (15 * 60)
    # Dart rounds ties away from zero, unlike Python's built-in round().
    rounded = math.copysign(math.floor(abs(quarters) + 0.5), quarters)
    offset = timedelta(minutes=15 * rounded)
    if abs(offset.total_seconds()) > 14 * 3600:
        raise ValueError("Inferred offset exceeds 14 hours; timestamps do not match")
    return offset


def timestamp_fields(value):
    """Yield timestamp fields, including nested profile metadata."""
    if isinstance(value, dict):
        for key, child in value.items():
            if key in TIMESTAMP_KEYS:
                yield value, key
            else:
                yield from timestamp_fields(child)
    elif isinstance(value, list):
        for child in value:
            yield from timestamp_fields(child)


def convert_session(session):
    """Convert timestamps in memory before saving the complete session."""
    if not isinstance(session, dict):
        raise ValueError("Expected a session JSON object")
    fields = [(parent, key, parse_timestamp(parent[key]))
              for parent, key in timestamp_fields(session)]
    offset = infer_offset(session) if any(t.tzinfo is None for _, _, t in fields) else None
    changed = 0
    for parent, key, timestamp in fields:
        if timestamp.utcoffset() == timedelta(0):
            continue
        if timestamp.tzinfo is None:
            timestamp = timestamp.replace(tzinfo=timezone(offset))
        parent[key] = timestamp.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        changed += 1
    return changed, offset


def main():
    changed = []
    errors = []
    paths = sorted(DATA_DIR.rglob("session.json"))
    if not paths:
        print(f"No session.json files found in {DATA_DIR}")
        return 1

    for path in paths:
        folder = path.parent.relative_to(DATA_DIR)
        try:
            session = json.loads(path.read_text(encoding="utf-8"))
            count, offset = convert_session(session)
            if not count:
                continue
            content = json.dumps(session, indent=2, ensure_ascii=False, allow_nan=False)
            path.write_text(content + "\n", encoding="utf-8")
            assumed = (f"UTC{offset.total_seconds() / 3600:+g}"
                       if offset is not None else "none (explicit offsets)")
            changed.append(f"{folder}: {count} timestamps, assumed timezone: {assumed}")
        except (ValueError, OSError, TypeError, KeyError, AttributeError) as error:
            errors.append(f"{folder}: {error}")

    print(f"Changed {len(changed)} of {len(paths)} session files:")
    for line in changed:
        print(f"  {line}")
    for error in errors:
        print(f"ERROR {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
