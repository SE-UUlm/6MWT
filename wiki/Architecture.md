# Architecture

The app follows a **feature-first layered architecture**: features own their presentation and domain code; shared infrastructure lives in `core/`.

## Layers

![Layer overview: the presentation layer uses the domain layer; the domain layer uses sensor and data layers; presentation also connects to sensors and data for platform integration.](assets/architecture-layers.svg)

Arrows indicate allowed dependencies (A → B means A may use B). Riverpod composes dependencies and state across all layers; go_router handles navigation.

## Features

- **`features/walk`** — the core 6-minute walk test: profile entry, preparation, active walk, result screen, distance estimation and walk-session lifecycle
- **`features/history`** — list and detail view of past test sessions
- **`features/home`** — entry point and navigation hub
- **`features/about`** — app info and legal notices
- **`features/instructions`** — standardized test instructions shown before a walk

## Core

`core/` contains shared infrastructure used across features:

- **`core/domain/`** — shared sample types, phase definitions, export models and interfaces
- **`core/data/`** — Drift/SQLite database, repositories for profiles, sessions and raw samples; see [Database Migrations](Database-Migrations.md)
- **`core/sensors/`** — GPS and pedometer sources, permission handling and platform integration
- **`core/presentation/`** — shared widgets and presentation utilities

## App

`app/` contains app-level wiring: router, provider composition and metadata services.

## Localization

`l10n/` contains user-facing strings as ARB files compiled to typed Dart classes via `flutter gen-l10n`. All UI text goes through these generated classes. The app supports German and English. Also see [Generation and checks](Development.md#generation-and-checks).

## Recording data flow

1. `WalkSession` starts required GPS and optional pedometer sources. Warm-up acquires sensors without recording or feeding estimators.
2. Initial and live samples use the shared `SensorSample` representation. Active recording sends them to the sample sink and to separate primary/comparison estimator instances.
3. The primary `GpsStepDistanceEstimator` supplies the displayed/persisted distance. Comparison failures are isolated; comparison results remain in memory for the current result and are not exported or stored in history.
4. Repositories persist profiles, sessions and raw samples in SQLite. Result/history export adds current device and app metadata to JSON.

See [Data and Tools](Data-and-Tools.md) for the export contract and [Distance Estimators](Distance-Estimators.md) for algorithm behavior.

## Lifecycle and platform boundaries

The keep-alive walk provider owns the active session independently of a screen. `WalkSessionLifecycle`, mounted above navigation, synchronizes an existing session when the app resumes. Deadlines use wall-clock time; an active test is not restored after process termination.

Android location uses a foreground notification and wake lock; iOS enables background location. These support recording and generally work but do not guarantee execution or sensor delivery under OS restrictions. GPS currently requests high accuracy with `distanceFilter: 1` (and a one-second requested Android interval).

Domain modules use shared interfaces; concrete platform metadata access lives in `app/`. UI-specific lifecycle behavior belongs in presentation. Database upgrades follow [Database Migrations](Database-Migrations.md).

## Visualizer replay

Opening Recording does not start estimator replay. Opening the Lab calculates in a background isolate; results are cached per loaded session and invalidated when files/references change. Each subsession receives fresh estimator instances. Errors are isolated and diagnostics are snapshotted. References use their actual overlapping UTC interval; a manual route's timing is an explicit constant-speed approximation.

Potential future experiments are tracked separately in [Outlook](Outlook.md).
