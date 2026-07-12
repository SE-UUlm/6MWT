# Architecture of the 6MWT App

## Concept
* Domain Layer: pure dart (no flutter) application logic
* Data Layer: Persistence, SQLite Storage
* Sensors: Sensor sources (GPS, steps, health) with interfaces
* Presentation Layer: Flutter GUI. Allowed to interact with Data Layer directly

This document describes the target architecture of the app for the Six-Minute Walk Test (6MWT).

## Requirements driving the architecture

- Multiple screens: instructions, test, personal data, results with fitness rating, history, settings
- The test must keep running in the background / with the screen locked
- Debug/research mode: record all raw data (GPS, sensors) at high frequency and export it as CSV/JSON
- Future sensor sources: HealthKit, Health Connect, Gadgetbridge (SpO2, heart rate), step counter, accelerometer
- Eventually a watch-only test without carrying a phone

## Core principles

Two boundaries are binding; everything else stays pragmatic:

1. **Domain logic knows nothing about Flutter.** The test flow (test engine), distance calculation, and fitness rating are pure Dart classes without Flutter imports. Only then can the test run in a foreground service (background operation) and be tested without an emulator.
2. **Sensors sit behind a common interface.** Every data source delivers a stream of timestamped measurements. New sources (health APIs, smartwatch) are added as additional implementations without changes to the engine or UI.

## Sensor pipeline (central abstraction)

```dart
abstract class SensorSource {
  String get id;                    // e.g. "gps", "healthkit_hr", "gadgetbridge_spo2"
  Stream<SensorSample> get samples; // sample = timestamp + type + values
  Future<void> start();
  Future<void> stop();
}
```

Independent consumers subscribe to the active sources:

| Consumer | Responsibility |
|---|---|
| **Recorder** | Persists every raw sample to the local DB. The CSV/JSON export for algorithm development is just a query over this table. |
| **Aggregators** | Condense streams into metrics, e.g. `DistanceEstimator` (interface; currently GPS-based, later swappable for step-based or sensor-fusion variants). |
| **Test engine** | State machine `idle → countdown → running → finished/aborted`; drives the timer and test flow, consumes the aggregators. |

Which sources are active is configured per test mode. This makes the watch-only test a non-special case: the watch is simply another `SensorSource`.

New distance algorithms can be developed and compared offline against the recorded raw data.

## Layers and folder structure

Feature-first with a shared core:

```
lib/
├── app/                    # MaterialApp + go_router setup
├── core/
│   ├── sensors/            # SensorSource interface + implementations
│   │   ├── sensor_source.dart      # the interface
│   │   ├── gps_source.dart         # wraps the LocationService
│   │   ├── location_service.dart   # geolocator wrapper (permissions, stream)
│   │   ├── pedometer_source.dart   # later
│   │   └── health_source.dart      # later (HealthKit/Health Connect)
│   ├── domain/             # pure Dart logic, no Flutter imports
│   │   ├── test_session.dart       # state machine of the test flow
│   │   ├── sensor_sample.dart      # timestamped measurement (all sources)
│   │   ├── sample_sink.dart        # recording interface used by the engine
│   │   ├── distance_estimator.dart # interface + GPS implementation
│   │   └── fitness_rating.dart     # later: reference values (e.g. Enright & Sherrill)
│   └── data/               # persistence
│       ├── database.dart           # drift (SQLite)
│       ├── test_repository.dart    # history: test results
│       ├── sample_repository.dart  # raw-data recording + export (implements SampleSink)
│       └── profile_repository.dart # weight, height, age, sex
├── features/
│   ├── onboarding/         # later: instructions
│   ├── test/               # test screen (display + start/stop only)
│   ├── results/            # later: result + fitness rating
│   ├── history/
│   ├── profile/            # personal data
│   ├── settings/           # later
│   └── debug/              # raw-data view + CSV/JSON export, GPS test
└── main.dart
```

The screens under `features/` are pure display and interaction layers: they observe the engine's state and trigger actions, but hold no test logic themselves. Navigating away during a running test therefore does not end it.

## Technology decisions

| Component | Choice | Rationale |
|---|---|---|
| State management / DI | **Riverpod** | Connects the UI to the engine without the engine knowing Flutter; easy to test. |
| Navigation | **go_router** | Declarative routes for the many screens. |
| Database | **drift** (SQLite) | Type-safe queries; suited for the large sample table; export is trivial. `shared_preferences` only for settings. |
| Background | **geolocator's built-in foreground service** (Android), background location mode (iOS) | Requires a UI-free engine. geolocator's `ForegroundNotificationConfig` (with wake lock) keeps GPS and the test timer alive in the same isolate — no separate service isolate needed. |
| Health data | **health** package | One API for HealthKit and Health Connect; fits behind `SensorSource`. |
| Steps / acceleration | `pedometer` / `sensors_plus` | Each its own `SensorSource`. |

## Deliberately left out

Full Clean Architecture (use cases, abstract repositories per entity, multiple mapping layers) — ceremony without benefit at this app size. The two core principles above are sufficient.

## Migration path from the current state

The existing code fits into the structure: `LocationService` → `GpsSource`, `DistanceCalculator` → implementation of `DistanceEstimator`, the logic from `WalkingTestScreen` (timer, subscription, start/stop/reset) → `TestSession` engine.

Order, each stage mergeable on its own:

1. ✅ Extract the test engine from the screen, introduce Riverpod and go_router, create the folder structure
2. ✅ Persistence: history and profile (drift)
3. ✅ Sample recording and CSV/JSON export (`SensorSource`/`SensorSample` pipeline, `SampleSink` → drift, share via share_plus)
4. ✅ Background operation (geolocator foreground service on Android, background location on iOS)
5. External sensor sources: step counter, health package, Gadgetbridge
