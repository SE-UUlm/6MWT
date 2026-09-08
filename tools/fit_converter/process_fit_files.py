#!/usr/bin/env python3
"""
Batch process Garmin FIT files and move them to corresponding session folders
=============================================================================

Finds all .fit files in `data/fit-files/`, matches each with its corresponding
session folder in `data/` based on start time, and converts them into the session
folder using convert_fit.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

# Add tools/fit_converter to sys.path so we can import directly
sys.path.insert(0, str(Path(__file__).parent / "fit_converter"))
from convert_fit import convert_fit_to_6mwt_dict


def parse_fit_filename_timestamp(fit_path: Path) -> datetime:
    """Parses timestamp from filename: Workout-gehen-2026-08-11T13_33_19+02_00.fit"""
    stem = fit_path.stem.replace("Workout-gehen-", "")
    parts = stem.split("T")
    date_part = parts[0]
    time_part = parts[1].replace("_", ":")
    return datetime.fromisoformat(f"{date_part}T{time_part}")


def main():
    repo_root = Path(__file__).parent.parent
    data_dir = repo_root / "data"
    fit_dir = data_dir / "fit-files"

    if not fit_dir.exists():
        sys.exit(f"Directory not found: {fit_dir}")

    # 1. Discover all session folders in data/
    sessions = []
    for p in data_dir.iterdir():
        session_file = p / "session.json"
        if p.is_dir() and session_file.exists():
            with open(session_file, "r", encoding="utf-8") as f:
                sdata = json.load(f)
                t = datetime.fromisoformat(sdata["startedAt"])
                sessions.append(
                    {
                        "time": t,
                        "dir": p,
                        "notes": sdata.get("notes", p.name),
                        "id": sdata.get("id"),
                    }
                )

    print(f"Found {len(sessions)} session folders in {data_dir.name}/\n")

    # 2. Discover and match FIT files
    fit_files = sorted(fit_dir.glob("*.fit"))
    if not fit_files:
        sys.exit("No .fit files found in fit-files/")

    print(f"Processing {len(fit_files)} FIT files:\n")

    for fit in fit_files:
        fit_t = parse_fit_filename_timestamp(fit)

        # Find closest session by timestamp
        best_diff = None
        best_session = None
        for s in sessions:
            diff = abs(s["time"].timestamp() - fit_t.timestamp())
            if best_diff is None or diff < best_diff:
                best_diff = diff
                best_session = s

        target_dir = best_session["dir"]
        session_notes = best_session["notes"]
        output_file = target_dir / f"{fit.stem}.json"

        notes_text = f"Garmin Referenz: {session_notes}"

        print(f"Processing: {fit.name}")
        print(f'  -> Matched to: 📁 "{target_dir.name}" (time delta: {best_diff:.1f}s)')

        # Convert using convert_fit_to_6mwt_dict
        json_data = convert_fit_to_6mwt_dict(
            str(fit),
            max_speed_ms=None,  # No speed filtering (keep raw jumps)
            timer_only=False,  # Keep all recorded points
            custom_notes=notes_text,
        )

        with open(output_file, "w", encoding="utf-8") as out:
            json.dump(json_data, out, indent=2, ensure_ascii=False)

        sess = json_data["sessions"][0]
        pos_count = sum(1 for sm in sess["samples"] if sm["type"] == "position")
        steps = (
            sess["samples"][-2]["values"]["cumulative_steps"]
            if len(sess["samples"]) >= 2
            else 0
        )

        print(
            f"  -> Saved: {output_file.name} ({pos_count} GPS points, {steps:.0f} steps, {sess['distance']:.1f}m)\n"
        )

    # Clean up any leftover top-level converted json in data/ if exists
    stray_json = data_dir / "Workout-gehen-2026-09-04T17_54_27+02_00.json"
    if stray_json.exists():
        stray_json.unlink()
        print(f"Cleaned up stray top-level {stray_json.name}")

    print(
        "All FIT files successfully converted and placed into their respective session folders!"
    )


if __name__ == "__main__":
    main()
