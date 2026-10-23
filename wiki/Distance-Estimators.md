# Distance Estimators

The app and Visualizer share implementations in `app/lib/features/walk/domain/estimators/`. All distances are meters. Reference tracks never calibrate replay algorithms.

## Algorithms and limits

| Estimator | Method and configuration | Main limits |
| --- | --- | --- |
| `GpsDistanceEstimator` | Sum consecutive GPS geographic distances; raw baseline | GPS jitter and jumps inflate distance; gaps cut corners |
| `FilteredGpsEstimator` | Reject invalid coordinates, excessive accuracy radius, nonpositive intervals and excessive speed; app comparison uses 20 m / 3 m/s | Missing accuracy is accepted; rejected fixes leave the previous anchor, including a potentially bad initial fix |
| `StepDistanceEstimator` | Step increments × fixed length (default comparison: 0.75 m) | Gait varies; first counter is a baseline; counter resets do not imply traveled steps |
| `GpsStepDistanceEstimator` | Accepted GPS segments plus calibrated step fallback; app primary uses 5-second GPS/fallback defaults | Calibration inherits GPS error; missing steps limit fallback; later GPS replaces overlapping provisional steps |
| `CalibratedStepDistanceEstimator` | Session median GPS-calibrated stride × observed steps; 10-second windows at 5-second strides | Revises earlier distance and may decrease; noisy GPS biases stride; uniform step rate assumed between batches |
| `AdaptiveGpsStepDistanceEstimator` | Accepted GPS edges plus steps only over gaps; stride interpolated from nearby good runs | Provisional tails can decrease; no route geometry inside gaps; raw GPS edges can still drift |
| `KalmanGpsDistanceEstimator` | Constant-velocity position filter, accuracy/speed/innovation gates and displacement threshold | Tight turns can lose distance; subthreshold final movement is not flushed; correlated drift and multipath may pass gates |
| `KalmanGpsStepDistanceEstimator` | Steps × scalar Kalman estimate of stride; accepted GPS fallback when steps are unavailable | Assumes roughly consistent gait; recalibration can decrease the total; missing or spurious steps remain errors |

## App integration

`app/lib/features/walk/domain/walk_session_provider.dart` configures a separate primary `GpsStepDistanceEstimator` and named comparison instances. They receive the same initial/live samples, excluding warm-up. Comparison errors disable that comparison for the run.

Only primary distance drives assessment and persistence. Comparison diagnostics appear in the detailed walk and current result, including release builds, but do not persist in history or JSON. No comparison is automatically promoted to primary.

## Configuration and assumptions

### Initial step length from profile data

`GpsStepDistanceEstimator` estimates the initial step length as
`heightCm / 100 * factor`. The factor is 0.415 for `male`, 0.413 for `female`,
and 0.414 for other or unspecified gender. Missing or invalid height (e.g. in older exports) uses
0.70 m. Age and weight are not used.

Once enough good GPS and step data are available, the learned step length
replaces this estimate and corrects earlier step-based distance.
The app uses the selected profile; Visualizer replay uses the recording's profile.

### Algorithm parameters

Configure Lab instances in `tools/6mwt_data_visualizer/lib/features/estimator_lab/estimators.dart`, then hot restart. The GUI displays the configured variants; it does not edit parameters. GPS/step variants compare 5, 10 and 15-second maximum GPS intervals, all with a 5-second fallback delay. Consult constructor/config defaults in the shared implementation when changing a parameter.

- Calibrated steps requires full GPS/step coverage, at least 6 steps and 5 m per window; accepted GPS has positive accuracy ≤10 m, speed ≤4 m/s and spacing ≤10 s. Stride ratios outside 0.25–2 m are rejected; median stride is clamped to 0.35–1.35 m, default 0.75 m.
- Adaptive fusion uses calibration windows wholly within adjacent good GPS runs and within 60 seconds of a gap boundary. With one side, hold that stride; with neither, use 0.75 m. No coverage from either sensor means no invented distance.
- GPS Kalman uses a local east/north plane and constant-velocity state. Reported accuracy supplies a heuristic measurement variance, not calibrated certainty. After a gap of more than 15 seconds without an accepted fix, two new plausible positions are required before resuming — this recovers from a bad initial fix without bridging the missing geometry. Default parameters:

  | Parameter | Default |
  | --- | ---: |
  | `maxAccuracy` | 20 m |
  | `maxSpeed` | 4 m/s |
  | `minPositionSigma` | 3 m |
  | `accelerationSigma` | 1.5 m/s² |
  | `innovationThreshold` | 9.21 |
  | `gapSeconds` | 15 s |
  | `minDistance` | 5 m |
  | `accuracyDistanceFactor` | 0.5 |

  `minDistance` was raised from the originally planned 2 m to 5 m after a stationary noise test (Gaussian noise, σ = 1 m per axis, reported accuracy 3 m) accumulated roughly 102 m at 1-second and 71 m at 5-second sampling over six minutes. No reference recordings were used to tune these defaults.

- Kalman GPS + steps learns stride from sufficiently straight GPS windows (endpoint/polyline ratio ≥0.9), at least 10 s and 8 steps. Turns and noisy sections are excluded from calibration. The learned stride applies retroactively to all earlier steps, so the displayed total can decrease after an update.
- Step-based models select a valid source, establish counter baselines and account for resets. Batched step timing is approximated uniformly between observations; sensor timestamps must remain ordered within each source.

## Reproducible comparisons

Run from `tools/6mwt_data_visualizer/` after [development setup](Development.md):

```sh
flutter test test/gps_step_benchmark_test.dart --reporter expanded
flutter test test/kalman_gps_benchmark_test.dart --reporter expanded
flutter test tool/compare_gps_gaps.dart --reporter expanded
flutter test tool/profile_loading.dart --reporter expanded
```

The gap comparison writes `build/gps_gap_comparison.md` and `.json`. Generated benchmark reports are local output, not documentation to commit outside the wiki. Profiling measures replay/chart preparation in the Flutter test runtime, not end-to-end release rendering.

Use the same recordings, algorithm configuration and reference windows for comparisons. The Lab stably sorts samples by recorded UTC time and preserves file order for ties; each run resets fresh instances. Replay totals may differ from persisted distance because of older algorithms, arrival order or incomplete data.

Reference deltas use only the shared time interval, with interpolation and rebasing at boundaries. Device references and manually drawn routes have different uncertainty; manual routes assume constant speed. Neither constitutes exact ground truth. Zero reference distance has no percentage delta. Retrospective calibration corrections can include earlier periods, so overlap deltas describe live curves rather than isolated hindsight distance.

Do not infer general accuracy from a small recording collection. Evaluate measured routes, slow walking, stops, turns, gaps and poor reception across devices. Current research proposals are in [Outlook](Outlook.md).

## Adding your own DistanceEstimator

Extend the app's `DistanceEstimator` (`totalDistance`, `addSample`, `reset`) using the app's `SensorSample` type. See `app/lib/features/walk/domain/estimators/experimental_estimators.dart` for the shared implementations. Keep algorithms independent of widgets, replay state and reference data.

Add the instance to the list in `tools/6mwt_data_visualizer/lib/features/estimator_lab/estimators.dart`, for example:

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
