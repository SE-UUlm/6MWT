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

### Phase 2 (implemented)

- **Distance & steps line chart**:
  - Interactive line chart plotted over relative session time (`mm:ss`)
  - **App GPS Distance** (meters) vs. **App Steps** (count)
  - **Reference GPS Distance** vs. **Reference Steps** (when reference data is present)
  - **Unified distance scale (meters)**:
    - Step count curves are converted to distance (meters) using an automatically computed **median step length** across rolling time windows (comparing \(\Delta \text{GPS}\) to \(\Delta \text{Steps}\))
    - The identical step length is applied to both App and Reference curves, enabling direct visual comparison with GPS tracks on the same axis
    - Step length badge in the toolbar displays the computed value (e.g. `~78 cm`) with detailed calculation info in tooltip
  - **Interactive legend & filter chips**: Click chips to toggle individual signals on/off
  - **Rich tooltip**: Hovering reveals exact time `mm:ss (Xs)` and precise interpolated values for every active signal
  - **Collapsible layout**: Toggle the chart on/off via the title bar button to switch between split view and full-height map

### Phase 3 (implemented)

- **Estimator Lab** – replay previously recorded sessions through the actual `DistanceEstimator` interface from the main app, imported through a local package dependency on `../../app`.
- **Multiple estimators and parameter variants** – compare the original app `GpsDistanceEstimator`, experimental filtered GPS and fixed step length simultaneously.
- **Configuration in code** – select estimators and parameters in the `List<DistanceEstimator>` returned by `lib/features/estimator_lab/estimators.dart`. The GUI contains only the graph with its legend and the results table.
- **Comparison timeline and table** – toggle curves, inspect values on hover, compare final distance against the stored app distance and the reference in meters and percent, and inspect rejected GPS counts.
- **Deterministic replay** – fresh/reset estimators, recorded UTC timestamps, stable chronological sample order, isolated errors, and automatic reruns when switching or reloading sessions.

## Drawing and comparing references

In **Recording**, click **Draw reference**, then click the map in walking order.
Pan and zoom as usual, use **Undo last point** for corrections, enter a name and
choose **Save reference**. **Cancel** discards the draft. You can draw and save
several alternative routes for the same recording.

Route distance is the sum of the geographic segments between clicked points.
Manual routes have no measured timestamps: their timeline assumes **constant
speed over the recording's active window**, with waypoint times proportional to
distance. They are labeled accordingly in both charts and are comparison data
only; they never enter the Estimator Lab's sensor replay.

Each reference has a name and the same color in the map, recording graph and Lab.
The graph legends toggle individual reference curves; the Lab table includes
meter and percentage differences for each reference over its own overlap.
Select a reference in the recording's information panel for detailed metrics.

Existing `reference.json` files remain supported. Session folders also load
`reference_*.json` and every JSON recording in `references/`. New drawn routes
are saved as separate JSON files in `references/`; the original files are not
modified. Standalone or multi-session JSON exports use an adjacent
`<export filename>.references/<encoded session id>/` directory. Keep these
sidecar directories with the recordings when moving them. Saved references
appear immediately and load again the next time the recording is opened.

## Using the Estimator Lab

1. Select a recorded session and open **Estimator Lab** above the map.
2. All estimators configured in `estimators.dart` run automatically. Use the graph legend to toggle curves and the table to compare distances and additional diagnostics.
3. To test another algorithm or parameter variant, edit the list in `createEstimators()` and hot restart the tool. Multiple instances of the same class with different parameters are allowed.

The replay feeds **all recorded app sensor samples** to each estimator, from the earliest to the latest recorded timestamp. It uses subsecond timing, preserves file order for timestamp ties, and does not run in real time. It does not use the reference recording or a whole-session step-length estimate to calibrate algorithms. The original estimator runs unchanged; replay totals can differ from the stored distance if historical app versions, sample arrival order, or incomplete recordings differ.

Reference distance uses the reference's cumulative `distance` values when available throughout the track, otherwise a GPS Haversine sum. The available overlap with the replay is displayed, interpolated at its boundaries and rebased to zero at the overlap start. A later start or earlier end does not hide the reference. Table reference deltas compare both distances over this shared interval only; hover the reference legend for its time range. A reference with no overlap or invalid/decreasing cumulative distance is unavailable. A zero reference distance has no percentage delta. Tooltips interpolate every visible curve at the same time in estimator order, with the reference last; times outside a curve's coverage show a dash rather than extrapolated values. The recording/map view retains its existing reference-window behavior.

### Experimental algorithms

- **Filtered GPS:** rejects invalid coordinates, reported accuracy radii above the threshold, nonpositive time intervals, and segment speeds above the threshold. Rejected fixes do not become the next segment's anchor. Missing accuracy is accepted. This simple filter can remain anchored at a bad first fix; it is a development baseline.
- **Steps:** cumulative step deltas multiplied by a fixed length. Uses the first valid cumulative-step source, ignores status-only events, and treats a counter decrease as a new baseline. No steps before the first sample are inferred.

These implementations are shared with the main app, where they run as live comparisons. The main app still uses the original GPS estimator for its primary distance and fitness assessment.

### Adding your own DistanceEstimator

Extend the app's `DistanceEstimator` (`totalDistance`, `addSample`, `reset`) using the app's `SensorSample` type. See `../../app/lib/features/walk/domain/experimental_estimators.dart` for the shared implementations. Keep algorithms independent of widgets, replay state and reference data.

Add the instance to the list in `estimators.dart`, for example:

```dart
List<DistanceEstimator> createEstimators() => [
  GpsDistanceEstimator(),
  MyDistanceEstimator(threshold: 10),
  MyDistanceEstimator(threshold: 20),
];
```

The tool uses the class name and list position to identify each curve. New instances are created for every session, and replay calls `reset()` before feeding samples. Failures are caught separately for each estimator. The app GPS implementation is imported directly, so changes to it are available after a hot restart/rebuild.

Optionally override `additionalInfo` to expose settings and calculation diagnostics:

```dart
@override
Map<String, String> get additionalInfo => {
  'Rejected GPS': '$rejected',
  'Threshold': '$threshold m',
};
```

The default getter returns an empty map. The tool snapshots the map after calculation and displays every entry in the **Additional info** column. No UI or replay changes are needed for new diagnostics. Clear any per-run counters in `reset()`.

The local app dependency also resolves its transitive plugins; generated desktop plugin registrations are therefore part of the tool. Replays themselves require no sensor permissions or live sensor access.

### Verification

```bash
flutter pub get
flutter analyze
flutter test
flutter build linux
```

Tests cover deterministic replay, production-estimator parity, outliers, step counter resets, exact reference boundaries, error isolation, diagnostic snapshots, matching curve/table/tooltip colors in light/dark themes and every recording in the repository's `data/` directory. Run them from `tools/6mwt_data_visualizer` within this repository.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.12
- Linux, macOS, or Windows

## Running

```bash
cd tools/6mwt_data_visualizer
flutter run -d linux    # or: -d macos / -d windows
```

On startup the tool automatically looks for `data/*.json` relative to the repository root. If no file is found, a 📂 button is shown in the sidebar for manual selection.

Not really necessary: For reliable satellite-tile access, create an ArcGIS access token with the
`premium:user:basemaps` privilege. Store it in a local
`arcgis.local.json` file:

```json
{
  "ARCGIS_ACCESS_TOKEN": "YOUR_TOKEN"
}
```

Then start the visualizer with:

```bash
flutter run -d linux \
  --dart-define-from-file=arcgis.local.json
```

This is the recommended way to run the tool. `arcgis.local.json` is ignored by
Git and must never be committed.

Without a token, the visualizer falls back to ArcGIS's anonymous legacy
endpoint, which may be slow or throttle requests.

## Release build

```bash
flutter build linux     # or: macos / windows
```

The binary is placed under `build/linux/x64/release/bundle/`.

## Tech stack

| Area | Package |
|---|---|
| Map | [`flutter_map`](https://pub.dev/packages/flutter_map) + Esri World Imagery |
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
│   ├── estimator_lab/
│   │   ├── estimator_lab.dart        # Comparison chart/table
│   │   ├── estimators.dart           # List of algorithms and parameters to compare
│   │   └── estimator_replay.dart     # App sample adapter, replay and reference alignment
│   ├── chart/
│   │   ├── distance_steps_chart.dart # Interactive fl_chart widget
│   │   └── session_chart_data.dart   # Series calculation & normalization
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
