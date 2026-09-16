# FIT to 6MWT JSON Converter

This tool converts Garmin (or Gadgetbridge) workout `.fit` files into sanitized `.json` files compatible with the 6MWT JSON export schema.

## Features

- **Privacy / Data Hygiene**: Completely removes sensitive telemetry:
  - ❌ Heart rate & zones
  - ❌ Power & cycling dynamics
  - ❌ Calories & metabolic metrics
  - ❌ Device serial numbers & user profile information
- **Preserved Reference Data**:
  - ✅ All raw GPS coordinates (`latitude`, `longitude`, `altitude`)
  - ✅ Speed (`speed` in m/s)
  - ✅ Garmin cumulative distance (`distance` in meters)
  - ✅ Cumulative steps (`cumulative_steps`) and cadence (`cadence` in rpm/spm)
- **Raw / Unfiltered by Default**:
  - Preserves all recorded points (including GPS jumps, outliers, and pauses) so they can be visually inspected and used to test outlier detection algorithms in the visualizer.
- **Direct Compatibility**:
  - Produces standard 6MWT JSON files that can be directly opened in the [6MWT Data Visualizer](../6mwt_data_visualizer/).

## Usage with `uv` (Recommended)

No manual virtual environment setup required – `uv` manages dependencies automatically via PEP 723 metadata:

```bash
# Convert a .fit file (creates <name>.json in the same folder)
uv run tools/fit_converter/convert_fit.py data/Workout-gehen-2026-09-04T17_54_27+02_00.fit
```

Or run within the `tools/fit_converter/` directory:

```bash
cd tools/fit_converter
uv run convert_fit.py ../../data/Workout-gehen-2026-09-04T17_54_27+02_00.fit
```

## Options

| Flag | Default | Description |
|---|---|---|
| `-o`, `--output` | `<input>.json` | Custom output path for the JSON file |
| `--notes` | Auto-generated | Custom notes text stored in the session object |
| `--max-speed` | `None` | Optional speed threshold in m/s (filters out points above this speed) |
| `--timer-only` | `False` | Optional: Only include records recorded during active timer intervals (drop pauses) |
| `--first-span-only` | `False` | Optional: Only include the first continuous timer span |
| `--trim-after-vehicle` | `False` | Optional: Trim records after speed exceeds `--max-speed` |
