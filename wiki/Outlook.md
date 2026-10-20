# Outlook

These are research ideas, not implemented changes or promised accuracy improvements. This documentation revision changes no algorithms, data formats or sensor settings.

## Health data integration

The `health` Flutter package provides a unified API over Apple HealthKit (iOS) and Health Connect (Android) and could be added as a new `SensorSource`. Both platforms expose heart rate, SpO₂, VO₂max, step count, distance and GPS routes, with permissions granted per metric. On iOS, starting an `HKWorkoutSession` lets the system collect and fuse GPS, accelerometer and barometer data automatically — enabling an indoor test without direct GPS access. On Android, each metric must be collected manually in a foreground service; there is no automatic sensor fusion, but an existing workout recorded by a watch feeding into Health Connect could be used as input.

The most significant scenario enabled by this is **watchOS / Apple Watch support**: Apple Watch Series 3 and later automatically records a weekly `sixMinuteWalkTestDistance` sample, and a watch-based workout session could replace the phone entirely, so the patient carries only the watch. For Android, Wear OS offers a similar `ExerciseClient` with combined GPS and accelerometer data.

See [issue #11](https://github.com/SE-UUlm/6MWT/issues/11) for the full API exploration and a breakdown of which metrics are available on each platform.

## GPS path smoothing

Investigate whether motion models for straight walking and gentle curves reduce GPS zigzag and overestimated path length. Compare against the existing raw GPS, threshold-filtered GPS and Kalman variants before adding another model.

The existing GPS Kalman estimator smooths positions with a motion model and gates movement; Kalman GPS + steps instead estimates step length. Neither establishes that all route geometry is recovered. Preserve real curves and shuttle turning points: smoothing that cuts corners can reduce error on one recording while hiding real movement on another.

Evaluate separately measured routes with straight segments, gentle curves, sharp turns, stops, slow walking and poor reception. Report distance error and turning-point behavior, not only smoother-looking maps. Keep device references and manually drawn routes separate because neither is exact ground truth.

## Experiment: distanceFilter 0

The current `LocationService` requests `distanceFilter: 1` on Android, iOS and other platforms. Compare it with `0` in a separate experiment; platform delivery intervals and power management still apply.

1. Collect new matched recordings on straights, curves, shuttle turns, at rest and under poor reception, across devices.
2. Keep algorithm versions and other settings fixed, and record which acquisition setting each run used.
3. Compare distance error against measured routes, sample counts/file size, gaps and energy consumption over comparable durations.
4. Replay the same algorithms and inspect whether additional samples improve turn detection or merely add stationary noise.

Already omitted GPS updates cannot be reconstructed from existing recordings. Offline replay alone cannot determine the acquisition or energy effects of changing this setting.
