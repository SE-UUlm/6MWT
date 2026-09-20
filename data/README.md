# 6MWT Recorded Test Data

This directory contains recorded 6-Minute Walk Test (6MWT) sessions used for testing, validation, and benchmarking the mobile app's distance estimation and step counting algorithms.

## Privacy & Adding New Data

> [!WARNING]
> **Do not dox yourself!**
> - Avoid recording GPS tracks starting or ending directly in front of your home or private residence. Choose public trails, parks, sports tracks, or open areas instead.
> - Raw fitness tracker recordings often contain sensitive personal health metrics (heart rate, power output, calories, sleep, device serial numbers, etc.). Never commit raw `.fit` files directly into the repository (they are gitignored by default).

## Directory & File Structure

Each walk session has its own folder inside `data/`, named after the session's description / notes (e.g. location or conditions).

An example session folder contains:

- **`session.json` (Required)**: The walk test session recorded by the **6MWT mobile app** running on the phone. Contains participant metadata, calculated distance, duration, and time-series sensor samples (`gps` positions and `pedometer` step counts).
- **`reference.json` (Optional Reference)**: A reference dataset recorded simultaneously with a smartwatch. Follows a matching JSON schema for direct comparison, containing watch-measured GPS positions, speed, altitude, Garmin distance, and step counts. All sensitive health telemetry has been stripped.
  *(Note: Sessions without a watch recording, such as Basauri, do not include a `reference.json`).*

## Converting Reference FIT Files

To convert new `.fit` files into sanitized `reference.json` files, use the scripts provided in [`tools/fit_converter/`](../tools/fit_converter/README.md).

Currently, this conversion pipeline has been tested with Garmin smartwatch workouts exported via **Gadgetbridge**.

See the **[FIT Converter Documentation](../tools/fit_converter/README.md)** for setup and usage instructions with `uv`.

## Visualizing Data

You can inspect, replay, and compare both the mobile app and reference tracks on satellite imagery using the desktop development tool in **[`tools/6mwt_data_visualizer/`](../tools/6mwt_data_visualizer/README.md)**.
