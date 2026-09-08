# 6MWT Data Visualizer

A Flutter desktop development tool for visualizing recorded 6-minute walk test sessions from the JSON export of the 6MWT app.

## Features

### Phase 1 (implemented)

- **Session list** – all sessions listed in a sidebar with date, distance, GPS point count, step sample count, phase status, and Reference badge
- **Satellite map** – GPS tracks rendered on Esri World Imagery (satellite tiles), making it easy to see terrain such as forest, urban canyons, or open fields
- **Dual-track visualization (App vs. Reference)**:
  - 📱 **6MWT App Track**: Blue polyline with green start marker and red end marker; accuracy circles visualize the `accuracy` radius of each position sample
  - 🎯 **Reference Track**: High-contrast dashed orange polyline with dedicated start/end markers to compare tracks and detect deviations
- **Interactive map controls**:
  - Independent toggles to show/hide 6MWT App track, Reference track, step markers, and accuracy circles
  - "Center / fit tracks" zooms and fits camera to display both tracks simultaneously
- **Dynamic map legend**:
  - Floating legend showing distance and GPS point count for both tracks, plus live delta (\(\Delta\)) in meters and percentage
- **GPS dots** – from zoom level 18 onwards, GPS samples are shown as small dots along the route
- **Segment labels** – zoom-adaptive labels at GPS points:
  - 🟢 `+X.X m` – Haversine distance to the previous GPS sample
  - 🔵 `+Y steps` – step delta (only `cumulative_steps` samples) since the previous GPS sample
  - Label density adapts automatically to the zoom level (every 10th point at low zoom, every point at zoom ≥ 19)
- **Session info panel & Reference Comparison** – overview of phase, duration, stored distance, participant profile, and a dedicated **Reference Comparison Card** (distance delta, step delta, duration difference, sample counts)
- **Folder structure auto-load** – on startup the tool automatically scans `data/` subfolders for `session.json` and automatically attaches `reference.json` when present
- **Folder & file picker** – buttons in the sidebar header to reload data, pick a custom session folder, or open individual JSON files

### Phase 2 (planned)

- Line chart: cumulative GPS distance vs. cumulative step count over time, to identify discrepancies between the two signals

### Phase 3 (planned)

- Integration of the `DistanceEstimator` from the main app: run distance calculations directly in the tool and tune parameters (e.g. outlier detection for GPS data, step-count fusion)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.12
- Linux, macOS, or Windows

## Running

```bash
cd tools/6mwt_data_visualizer
flutter run -d linux    # or: -d macos / -d windows
```

On startup the tool automatically looks for `data/*.json` relative to the repository root. If no file is found, a 📂 button is shown in the sidebar for manual selection.

## Release build

```bash
flutter build linux     # or: macos / windows
```

The binary is placed under `build/linux/x64/release/bundle/`.

## Tech stack

| Area | Package |
|---|---|
| Map | [`flutter_map`](https://pub.dev/packages/flutter_map) + Esri World Imagery (free, no API key required) |
| Coordinates | [`latlong2`](https://pub.dev/packages/latlong2) |
| State management | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) + `riverpod_annotation` |
| File picker | [`file_picker`](https://pub.dev/packages/file_picker) |
| Distance calculation | Custom Haversine implementation (`lib/core/domain/haversine.dart`) |

## Project structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── data/
│   │   └── session_loader.dart       # JSON parsing & file discovery
│   └── domain/
│       ├── export_data.dart          # Top-level export model
│       ├── haversine.dart            # Distance calculation
│       ├── sensor_sample.dart        # SensorSample model (mirrored from main app)
│       └── session.dart              # Session & Profile models
├── features/
│   ├── home/
│   │   └── home_screen.dart          # Root layout (sidebar + detail)
│   ├── map/
│   │   ├── gps_track_layer.dart      # Polyline, start/end markers, GPS dots
│   │   ├── session_map.dart          # FlutterMap with satellite tiles
│   │   └── step_marker_layer.dart    # Zoom-adaptive segment labels
│   ├── session_detail/
│   │   ├── session_detail_screen.dart
│   │   └── session_info_panel.dart   # Metadata panel
│   └── session_list/
│       ├── session_list_panel.dart   # Sidebar with auto-load
│       └── session_list_tile.dart
└── providers/
    ├── providers.dart                # Riverpod providers
    └── providers.g.dart              # (generated)
```

## Development

After modifying Riverpod annotations, re-run the code generator:

```bash
dart run build_runner build
```
