# Data and Tools

## Recordings and references

Keep each recording in a folder under `data/` with `session.json` and, optionally, `reference.json`. Several `session_*.json` files in one folder form a group of device recordings; their timestamps and samples stay independent. References can also use `reference_*.json` or JSON files in `references/`.

The [Visualizer](Visualizer.md) opens both individual exports and folders. Release archives do not contain these example recordings. See the repository's [data directory](../data/) for replay fixtures.

Drawn references are separate files in `references/`. Standalone/multi-session exports use `<export filename>.references/<encoded session id>/` sidecars. Move these with their export. Manual routes have no measured timing: comparisons assume constant speed across the active window.

## Export format

Single exports put session fields, `profile` and `samples` directly at the top level alongside metadata. History exports contain `profiles` and `sessions` arrays plus metadata; each session carries its own samples and links to a profile through `profileId`. Sessions contain an ID, UTC `startedAt`, duration in seconds, distance in meters, phase, profile and sensor `samples`. Samples carry timestamp, type, source ID and a values map. Preserve sample order for equal timestamps.

| Sample | Values |
| --- | --- |
| Position (`position`) | `latitude`, `longitude` in degrees; `accuracy`, `altitude` in meters; `speed` in m/s; `heading` in degrees |
| Steps (`steps`) | `cumulative_steps`; status events are not step increments |
| Converted reference | May additionally include cumulative `distance` in meters and `cadence` |

Check the [export implementation](../app/lib/core/presentation/session_export_service.dart) and [Visualizer loader](../tools/6mwt_data_visualizer/lib/core/data/session_loader.dart) before writing another producer. 

## UTC timestamps

Create and store timestamps in UTC. Sensor sources normalize their timestamps
before creating `SensorSample`; session starts use `DateTime.now().toUtc()`.
Profile creation uses the database's UTC timestamp default. JSON exports convert
all timestamps to UTC explicitly, including older records, and include `Z`.

For dates and clock times in the UI, call `.toLocal()` before formatting to use
the current device timezone. Durations such as the test countdown are unchanged.

## Export metadata

Both single-session and history JSON exports include `deviceInfo` and `appInfo`
objects at the top level. They describe the device and installed app **at export
time**, not at the original recording time. Existing session data is unchanged.

- `deviceInfo`: `manufacturer`, `model`, `os`, `osVersion`, `deviceId`, and
  `deviceIdType`. iOS models use the machine identifier (for example `iPhone17,1`).
- `appInfo`: `version`, `buildNumber` (both strings), and the full `commitHash`.
- Unavailable values are JSON `null`; metadata lookup failures do not prevent export.

Android uses `Settings.Secure.ANDROID_ID` (`deviceIdType: androidId`), scoped to
signing key, user, and device on Android 8+. It generally survives reinstalling
with the same signing key. iOS uses `identifierForVendor`
(`deviceIdType: identifierForVendor`), shared by apps from the same vendor. It can
change after all that vendor's apps are removed and one is reinstalled. Neither
is a permanent hardware or strictly per-installation ID. No identifier is stored
in our database. Other platforms currently export only OS information.

Gradle and Xcode automatically embed `git rev-parse HEAD` during native builds.
Incremental native builds refresh the hash; hot reload does not. Uncommitted changes 
are not captured by the hash. Builds without Git/repository metadata emit a build warning 
and export `commitHash: null`, replacing any previous value. Commit embedding is
implemented for Android and iOS.

The annotated `appInfoProvider` in `app/metadata_providers.dart`
exposes the installed version, build number, and embedded hash for reuse by the
About screen. Models and metadata interfaces live in `core/domain`; provider composition and OS/plugin access live in `app/metadata_providers.dart`, `app/metadata_service.dart` and `app/platform_metadata.dart`. Session export composition lives in `core/presentation/session_export_service.dart`. 

## Privacy and contributions

Record on public routes; avoid exposing homes or private start/end locations. GPS tracks and profile data remain sensitive even after health telemetry is removed. Review JSON before sharing. Raw FIT files are ignored by Git and must not be committed. Use synthetic profiles for screenshots; keep images centrally in `wiki/assets/`. To regenerate the app screenshots, see [App screenshots](#app-screenshots).

## FIT converter

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) and run from the repository root. Script metadata declares Python/dependency requirements and uv installs them automatically. This pipeline has been used with Garmin workouts exported through Gadgetbridge.

```sh
uv run tools/fit_converter/convert_fit.py workout.fit -o reference.json
```

The converter preserves GPS coordinates, altitude, speed, cumulative distance, steps and cadence, removing heart rate, calories, power, serial numbers and user profiles. Coordinates can still identify a person. By default it retains GPS jumps, outliers and pauses for algorithm evaluation.

### Options

| Flag | Default | Description |
|---|---|---|
| `-o`, `--output` | `<input>.json` | Custom output path for the JSON file |
| `--notes` | Auto-generated | Custom notes text stored in the session object |
| `--max-speed` | `None` | Optional speed threshold in m/s (filters out points above this speed) |
| `--timer-only` | `False` | Optional: Only include records recorded during active timer intervals (drop pauses) |
| `--first-span-only` | `False` | Optional: Only include the first continuous timer span |
| `--trim-after-vehicle` | `False` | Optional: Trim records after speed exceeds `--max-speed` |

## Synthetic data

Generate deterministic six-minute walks with exact ground truth to probe distance estimators in situations that are rare or hard to record. Requires Python 3.10+ and no packages. From the repository root:

```sh
python3 tools/synthetic_data/generate.py
```

**Replaces `data/synthetic/` completely.** `-o <dir>` writes elsewhere; `--only <name> ...` regenerates selected scenarios without deleting the others or rewriting the README. Each scenario folder contains an app-style `session.json` (GPS `position` and pedometer `steps` samples, starting with a counter baseline) and a `reference.json` with the simulated route as 1 Hz positions and cumulative `distance`. The generated `data/synthetic/README.md` lists every scenario with its true distance, steps, mean stride and GPS fix count. Coordinates and the profile are synthetic.

### Scenarios

Scenarios are defined in `scenarios()` at the end of the script; names are prefixed by the aspect they test. Unless stated otherwise, a walk uses good 1 Hz GPS, a counter reading every second, 0.72 m stride and 1.85 steps/s.

| Prefix | Covers |
| --- | --- |
| `gps_` | Good, medium, intermittently bad with an outage, mostly bad, indoor (rare 60 m fixes), inaccurate (~30 m) but stable on a long straight, positions advancing too slowly with catch-up jumps (seen on a OnePlus), multipath jumps, one fix every ~5 s (older app versions) |
| `route_` | Zigzag, circles, 30 m and 10 m shuttles with slowdown at turns, stops with GPS jitter |
| `steps_` | Counter readings per step, every 10 steps, in 30 s batches or 10 s late; broken counters (undercounting, overcounting, frozen, erratic, counting while standing, missing) |
| `stride_` | Short (0.45 m) and long (0.95 m) strides, fatigue during a GPS outage, stride changes measured by GPS before a gap, alternating stride with intermittent GPS |

### Models

The walker follows a polyline with cadence and stride profiles plus small cadence variation; true distance and steps are integrated every 50 ms. GPS presets (`GOOD`, `MEDIUM`, `BAD`, `VERY_BAD`, `OUTAGE`, `INACCURATE_STABLE`) model fused phone positions: a slowly wandering offset driven by a correlated error velocity, little independent per-fix noise and a reported accuracy radius. They are loosely calibrated against the 1 Hz recordings in `data/`: good conditions add about 1–3 % to a raw GPS sum, medium ones roughly 12–16 %. Reported speed reads about 10 % low, as observed on real devices. Step counter output is derived from the true step count with optional factors, freezes, delays, ghost steps and delivery modes.

### Evaluating estimators

Open `data/synthetic/` in the [Visualizer](Visualizer.md); the Estimator Lab compares each estimator against the ground-truth reference. For tables across all scenarios, load the folder in a Visualizer test with `loadBenchmarkRecordings('../../data/synthetic')` from `tool/benchmark_support.dart` and reuse `compareReferences` and `summaryLines`, as in `test/gps_step_benchmark_test.dart`. The existing benchmarks read only the top level of `data/`, so synthetic walks never mix with real recordings.

Use synthetic results to find failure modes and check that a change does not break other situations, not to claim real-world accuracy. The sensor models are simplified, scenarios are hand-picked, and parameters tuned only on them will overfit. Confirm improvements on real recordings, keeping 1 Hz and 5 s GPS recordings apart. Scenarios without steps and GPS, or with a stride change during an outage, have no recoverable answer and test graceful degradation only.

## Timestamp converter

Normalize older recordings whose step timestamps use local time while GPS uses UTC. Not really needed anymore.

Requires Python 3.10+. From the repository root:

```sh
python3 tools/session_timestamps_to_utc/convert.py
```

**Overwrites changed `data/**/session.json` files without backups or options.** Back up files and inspect the diff afterward. It infers a local-time offset from `startedAt` and the first UTC GPS sample, rounded to 15 minutes, assuming they refer to approximately the same moment. Existing UTC timestamps and references are unchanged. Insufficient information causes a skip with an error. This repairs older local step timestamps; it is not a general timezone conversion tool and does not process every `session_*.json` automatically.

## App screenshots

Regenerate the six app screenshots in the repository README (`wiki/assets/app-*.png`). Requires Python 3.10+, ImageMagick 7, Flutter and exactly one running Android emulator. From `app/`:

```sh
python3 tool/screenshots/take_screenshots.py            # all screens
python3 tool/screenshots/take_screenshots.py walk home  # selected screens
```

**Overwrites the screenshots in `wiki/assets/`.** For each screen, the script builds `tool/screenshots/main.dart` as a release APK, installs it and captures the emulator screen. The entry point runs the real app in English with an in-memory database, a synthetic profile (Demo, 30 years, 170 cm, 65 kg), five history entries and a simulated walk on the Uni Ulm campus instead of real sensors. The script fills in the profile form, swipes the walk screen to its detail view, rounds the corners and adds a thin outline.

Android's demo mode gives the status bar a fixed time, full battery and Wi-Fi and no notifications. The emulator does not draw the mobile signal icon in demo mode, so it is hidden. Afterward, the script leaves demo mode and uninstalls the release app. It stops if a release build (`de.uniulm.in.se.sixmwt`) is already installed, so that build is not replaced; the debug build is not affected. Window size and corner radius are tuned for a Pixel 9 Pro XL emulator.
