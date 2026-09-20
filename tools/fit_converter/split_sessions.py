#!/usr/bin/env python3
"""
Split 6MWT Export JSON into per-session folders
==============================================

Reads a 6MWT export JSON file and creates a folder for each session inside `data/`
named after the session's `notes`. Inside each folder, a `session.json` file is
written containing all session fields along with the embedded `profile` object.
"""

import json
from pathlib import Path
import sys


def split_sessions(
    export_path: str = "data/6mwt_export.json", output_dir: str = "data"
):
    export_file = Path(export_path)
    if not export_file.exists():
        sys.exit(f"File not found: {export_file}")

    with open(export_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    profiles_by_id = {p["id"]: p for p in data.get("profiles", [])}
    sessions = data.get("sessions", [])

    base_out = Path(output_dir)
    created_folders = []

    for s in sessions:
        notes = (s.get("notes") or s.get("id", "session")).strip()
        # Sanitize folder name just in case
        folder_name = "".join(c for c in notes if c not in r'<>:"/\|?*').strip()
        if not folder_name:
            folder_name = s["id"]

        session_folder = base_out / folder_name
        session_folder.mkdir(parents=True, exist_ok=True)

        # Build session object with embedded profile
        session_copy = dict(s)
        profile_id = s.get("profileId")
        if profile_id in profiles_by_id:
            session_copy["profile"] = profiles_by_id[profile_id]
        else:
            session_copy["profile"] = None

        target_file = session_folder / "session.json"
        with open(target_file, "w", encoding="utf-8") as out:
            json.dump(session_copy, out, indent=2, ensure_ascii=False)

        created_folders.append((session_folder, target_file, len(s.get("samples", []))))

    return created_folders


def main():
    export_path = (
        sys.argv[1] if len(sys.argv) > 1 else "data/6mwt_export Brauchbar.json"
    )
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "data"

    print(f"Reading: {export_path}")
    folders = split_sessions(export_path, output_dir)
    print(f"\nCreated {len(folders)} session folders:")
    for folder, file_path, sample_count in folders:
        print(f"  📁 {folder.name}/ -> {file_path.name} ({sample_count} samples)")


if __name__ == "__main__":
    main()
