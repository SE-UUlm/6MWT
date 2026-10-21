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

Record on public routes; avoid exposing homes or private start/end locations. GPS tracks and profile data remain sensitive even after health telemetry is removed. Review JSON before sharing. Raw FIT files are ignored by Git and must not be committed. Use synthetic profiles for screenshots; keep images centrally in `wiki/assets/`.

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

## Timestamp converter

Normalize older recordings whose step timestamps use local time while GPS uses UTC. Not really needed anymore.

Requires Python 3.10+. From the repository root:

```sh
python3 tools/session_timestamps_to_utc/convert.py
```

**Overwrites changed `data/**/session.json` files without backups or options.** Back up files and inspect the diff afterward. It infers a local-time offset from `startedAt` and the first UTC GPS sample, rounded to 15 minutes, assuming they refer to approximately the same moment. Existing UTC timestamps and references are unchanged. Insufficient information causes a skip with an error. This repairs older local step timestamps; it is not a general timezone conversion tool and does not process every `session_*.json` automatically.
