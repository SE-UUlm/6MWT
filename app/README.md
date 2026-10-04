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

The session provider configures the primary `GpsDistanceEstimator` and additional
named estimators in `lib/features/walk/domain/walk_session_provider.dart`. Each
entry must own a separate estimator instance. All estimators receive the same
initial and live sensor samples, excluding warm-up samples.

The default comparisons are filtered GPS (maximum accuracy radius 20 m, maximum
speed 3 m/s) and steps (fixed step length 0.75 m). Their shared implementations
also power the data visualizer. Diagnostics appear below the detailed walking
view and between test details and profile information on the result screen,
including in release builds. A failed comparison is disabled until the next run.

Comparison results are kept in memory for the current test only. They survive
the session reset when navigating to its result, but are not stored in history
or JSON exports. The primary GPS distance remains the basis for assessment and
persistence.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
