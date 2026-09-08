#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "fitparse>=1.2.0",
# ]
# ///
"""
FIT to 6MWT JSON Converter
==========================

Converts Garmin / Gadgetbridge FIT workout files into sanitized JSON files
following the 6MWT export schema.

Features:
- Strips sensitive telemetry: NO heart rate, power, calories, personal profiles, or serial numbers.
- Retains reference walk data: GPS positions (lat, lon, altitude, speed, Garmin distance) and steps (cumulative steps, cadence).
- Filtering disabled by default: Preserves all recorded data (including GPS jumps/outliers) for testing outlier detection.
- Compatible format: Converted JSON files can be opened directly in the 6MWT Data Visualizer desktop tool.

Usage with uv (recommended):
    uv run tools/fit_converter/convert_fit.py data/Workout-gehen-2026-09-04T17_54_27+02_00.fit
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import fitparse
except ImportError:
    sys.exit(
        "Error: 'fitparse' library is required.\n"
        "Run with uv: uv run tools/fit_converter/convert_fit.py <file.fit>\n"
        "Or: pip install fitparse"
    )


def semicircles_to_degrees(semicircles: int) -> float:
    """Converts Garmin semicircle coordinates to degrees."""
    return float(semicircles) * (180.0 / (2**31))


def get_timer_spans(fitfile):
    """
    Extracts active workout timer spans (start to stop/stop_all events).
    Returns list of (start_time, stop_time) tuples.
    """
    spans = []
    current_start = None
    for event in fitfile.get_messages("event"):
        etype = event.get_value("event")
        if etype == "timer":
            subtype = event.get_value("event_type")
            ts = event.get_value("timestamp")
            if subtype == "start":
                current_start = ts
            elif subtype in ("stop", "stop_all", "stop_disable_all") and current_start:
                spans.append((current_start, ts))
                current_start = None
    return spans


def is_in_timer_spans(timestamp, spans):
    """Checks if a timestamp falls within any active timer span."""
    if not spans:
        return True
    return any(start <= timestamp <= stop for start, stop in spans)


def convert_fit_to_6mwt_dict(
    fit_path: str,
    max_speed_ms: float | None = None,
    timer_only: bool = False,
    first_span_only: bool = False,
    trim_after_vehicle: bool = False,
    custom_notes: str | None = None,
) -> dict:
    """
    Parses a FIT file and returns a dictionary compatible with the 6MWT export schema.
    By default, all valid GPS records are preserved without speed or pause filtering.
    """
    fitfile = fitparse.FitFile(fit_path)

    # 1. Inspect session summary message
    session_msg = next(fitfile.get_messages("session"), None)
    sport = "walking"
    total_strides = 0

    if session_msg:
        sport = session_msg.get_value("sport") or "walking"
        total_strides = session_msg.get_value("total_strides") or 0

    # In Garmin FIT files, a 'stride' is a complete two-step cycle (left + right).
    # For walking/running, 1 stride = 2 steps.
    total_steps = total_strides * 2 if total_strides else 0

    # 2. Timer spans
    timer_spans = get_timer_spans(fitfile)
    if first_span_only and timer_spans:
        timer_spans = [timer_spans[0]]

    # 3. Read and filter record messages
    records = list(fitfile.get_messages("record"))
    if not records:
        raise ValueError("No 'record' messages found in FIT file.")

    filtered_records = []
    vehicle_detected = False

    for r in records:
        ts = r.get_value("timestamp")
        lat = r.get_value("position_lat")
        lon = r.get_value("position_long")
        speed = r.get_value("enhanced_speed") or r.get_value("speed") or 0.0

        # Require valid GPS coordinates
        if lat is None or lon is None or ts is None:
            continue

        # Optional vehicle speed filter
        if max_speed_ms is not None and speed > max_speed_ms:
            if trim_after_vehicle:
                vehicle_detected = True
                break
            continue

        if vehicle_detected:
            break

        # Optional timer span filter
        if timer_only and timer_spans and not is_in_timer_spans(ts, timer_spans):
            continue

        filtered_records.append(r)

    if not filtered_records:
        raise ValueError(
            "All records were filtered out. Check filter arguments."
        )

    # 4. Integrate cadence over time to obtain cumulative steps for each record
    raw_step_counts = []
    cum_steps = 0.0
    prev_time = filtered_records[0].get_value("timestamp")

    for r in filtered_records:
        ts = r.get_value("timestamp")
        dt = (ts - prev_time).total_seconds()
        cadence_rpm = r.get_value("cadence") or 0
        # Garmin cadence is in strides/min (rpm). Multiply by 2 for steps/min (spm).
        cadence_spm = cadence_rpm * 2
        if 0 < dt < 60:
            cum_steps += (cadence_spm / 60.0) * dt
        raw_step_counts.append(cum_steps)
        prev_time = ts

    # Scale integrated steps to match session total_steps if known and > 0
    scale_factor = 1.0
    if total_steps > 0 and cum_steps > 0:
        scale_factor = total_steps / cum_steps

    # 5. Build SensorSample items matching the 6MWT schema
    samples = []
    sample_id = 1

    for i, r in enumerate(filtered_records):
        ts = r.get_value("timestamp")
        iso_timestamp = ts.replace(tzinfo=timezone.utc).isoformat()

        lat = semicircles_to_degrees(r.get_value("position_lat"))
        lon = semicircles_to_degrees(r.get_value("position_long"))
        alt = r.get_value("enhanced_altitude") or r.get_value("altitude")
        speed = r.get_value("enhanced_speed") or r.get_value("speed") or 0.0
        distance = r.get_value("distance") or 0.0
        cadence_rpm = r.get_value("cadence") or 0
        cadence_spm = cadence_rpm * 2

        # Step sample
        step_val = round(raw_step_counts[i] * scale_factor, 1)
        samples.append(
            {
                "id": sample_id,
                "timestamp": iso_timestamp,
                "sourceId": "garmin_watch",
                "type": "steps",
                "values": {
                    "cumulative_steps": float(step_val),
                    "cadence": float(cadence_spm),
                },
            }
        )
        sample_id += 1

        # Position sample
        pos_values = {
            "latitude": round(lat, 7),
            "longitude": round(lon, 7),
            "speed": round(float(speed), 3),
            "distance": round(float(distance), 2),
        }
        if alt is not None:
            pos_values["altitude"] = round(float(alt), 1)

        samples.append(
            {
                "id": sample_id,
                "timestamp": iso_timestamp,
                "sourceId": "garmin_watch",
                "type": "position",
                "values": pos_values,
            }
        )
        sample_id += 1

    # 6. Compute session metadata
    first_time = filtered_records[0].get_value("timestamp")
    last_time = filtered_records[-1].get_value("timestamp")
    duration_sec = int((last_time - first_time).total_seconds())
    final_distance = (filtered_records[-1].get_value("distance") or 0.0) - (
        filtered_records[0].get_value("distance") or 0.0
    )

    fit_filename = Path(fit_path).stem
    notes = (
        custom_notes
        if custom_notes
        else f"Garmin Referenz: {sport.capitalize()} ({fit_filename})"
    )

    session_id = f"garmin_{first_time.strftime('%Y%m%dT%H%M%SZ')}"

    session_data = {
        "id": session_id,
        "notes": notes,
        "startedAt": first_time.replace(tzinfo=timezone.utc).isoformat(),
        "duration": duration_sec,
        "distance": round(float(final_distance), 2),
        "phase": "finished",
        "profileId": 1,
        "samples": samples,
    }

    export_json = {
        "exportedAt": datetime.now(timezone.utc).isoformat(),
        "profiles": [
            {
                "id": 1,
                "name": "Garmin Watch",
                "timestamp": first_time.replace(tzinfo=timezone.utc).isoformat(),
                "height": 0,
                "age": 0,
            }
        ],
        "sessions": [session_data],
    }

    return export_json


def main():
    parser = argparse.ArgumentParser(
        description="Convert Garmin/Gadgetbridge FIT workouts to sanitized 6MWT JSON format."
    )
    parser.add_argument(
        "fit_file",
        help="Path to the input .fit file",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Path for the output .json file (defaults to <fit_filename>.json in the same folder)",
    )
    parser.add_argument(
        "--max-speed",
        type=float,
        default=None,
        help="Optional max speed threshold in m/s (filters out records above this speed). Default: None (no filtering).",
    )
    parser.add_argument(
        "--timer-only",
        action="store_true",
        help="Optional: Only include records recorded during active timer intervals (drop pauses). Default: False.",
    )
    parser.add_argument(
        "--first-span-only",
        action="store_true",
        help="Optional: Only include the first continuous timer span. Default: False.",
    )
    parser.add_argument(
        "--trim-after-vehicle",
        action="store_true",
        help="Optional: Trim records after speed exceeds --max-speed. Default: False.",
    )
    parser.add_argument(
        "--notes",
        help="Custom notes string for the session",
    )

    args = parser.parse_args()

    fit_path = Path(args.fit_file)
    if not fit_path.exists():
        sys.exit(f"File not found: {fit_path}")

    output_path = args.output
    if not output_path:
        output_path = fit_path.with_suffix(".json")

    print(f"Reading: {fit_path}")
    try:
        data = convert_fit_to_6mwt_dict(
            str(fit_path),
            max_speed_ms=args.max_speed,
            timer_only=args.timer_only,
            first_span_only=args.first_span_only,
            trim_after_vehicle=args.trim_after_vehicle,
            custom_notes=args.notes,
        )
    except Exception as e:
        sys.exit(f"Conversion error: {e}")

    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    session = data["sessions"][0]
    pos_count = sum(1 for s in session["samples"] if s["type"] == "position")
    step_count = sum(1 for s in session["samples"] if s["type"] == "steps")
    final_step = (
        session["samples"][-2]["values"]["cumulative_steps"]
        if len(session["samples"]) >= 2
        else 0
    )

    print(f"\nSuccessfully converted FIT -> JSON:")
    print(f"  Output: {output_file}")
    print(f"  Duration: {session['duration']} s ({session['duration'] // 60}m {session['duration'] % 60}s)")
    print(f"  Distance: {session['distance']} m")
    print(f"  Steps: {final_step}")
    print(f"  Position samples: {pos_count}")
    print(f"  Step samples: {step_count}")
    print(f"  Filtering: Disabled (all {pos_count} raw GPS positions preserved).")
    print(f"  Sensitive telemetry stripped: Heart rate, power, calories, personal data.")


if __name__ == "__main__":
    main()
