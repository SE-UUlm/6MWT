# six_minute_walk_test

A new Flutter project.

## Timestamps

Create and store timestamps in UTC. Sensor sources normalize their timestamps
before creating `SensorSample`; session starts use `DateTime.now().toUtc()`.
Profile creation uses the database's UTC timestamp default. JSON exports convert
all timestamps to UTC explicitly, including older records, and include `Z`.

For dates and clock times in the UI, call `.toLocal()` before formatting to use
the current device timezone. Durations such as the test countdown are unchanged.
The current screens do not display calendar dates or clock times.

## Distance comparisons

See [Distance Estimators](../wiki/Distance-Estimators.md) in the wiki for the
algorithms, app integration, configuration, diagnostics, and benchmarks.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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
Normal `flutter run` and `flutter build` commands need no extra arguments, locally
or in CI. A PR build may embed its checked-out merge commit. Incremental native
builds refresh the hash; hot reload does not. Uncommitted changes are not captured
by the hash. Builds without Git/repository metadata emit a build warning and
export `commitHash: null`, replacing any previous value. Commit embedding is
implemented for Android and iOS.

The annotated `appInfoProvider` in `core/domain/app_info.dart`
exposes the installed version, build number, and embedded hash for reuse by the
About screen. Models, export composition, and their annotated providers live in `core/domain`;
global OS/plugin access lives in `app/metadata_service.dart` and
`app/platform_metadata.dart`. The home screen info button opens `/about`, showing build metadata, project
information, authors, the repository link, and bundled open-source licenses.
Unavailable metadata is displayed as “Not available”; the other content remains
accessible.
