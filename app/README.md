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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
