# GPS-calibrated step comparisons

`CalibratedStepDistanceEstimator` uses observed cumulative-step increments times
an evolving session median step length. It is available as a comparison in the
app and Estimator Lab; primary/persisted distance is unchanged.

Calibration uses 10-second windows at 5-second strides, aligned on the common
GPS/step observation interval. Each window needs full sensor-time coverage,
at least 6 steps and 5 meters. GPS segments require positive accuracy <= 10 m,
speed <= 4 m/s, and fix spacing <= 10 seconds. Invalid GPS breaks continuity;
two plausible successive fixes establish coverage again. No outlier return
segment or missing-data bridge is used for calibration.

Window ratios outside 0.25–2 m/step are rejected. The upper median is clamped to
0.35–1.35 m, matching the Recording view's bounds; 0.75 m is the default. These
bounds can underestimate very short steps. The Recording view itself remains
unchanged; unlike that historical calculation the new estimator never reads
reference tracks and never independently shifts the sensor timelines to zero.

Each sensor kind uses its first valid source. Duplicate/backward timestamps and
foreign sources are ignored; step counter resets start a new baseline. Steps
are distributed uniformly between counter timestamps, including batched events.
Calibration never extrapolates beyond observed step or GPS coverage. The result
can decrease when new calibration revises earlier steps. Diagnostics explicitly
mark it as provisional. GPS noise with apparently good accuracy can still bias
calibration; the accuracy field is not a guarantee of true positional error.

Tests cover known lengths, batched/offset timestamps, rejected fixes, counter
resets, source isolation, downward revisions, and deterministic live/replay reset.

## Local GPS/step fusion

`AdaptiveGpsStepDistanceEstimator` sums accepted GPS edges and fills only their
complement with steps. An open tail is provisionally steps until a subsequent
GPS fix confirms or rejects coverage. Replacing that estimate can reduce the
live total. Consecutive good GPS edges form a run; bad accuracy, implausible speed
or a >10-second interval separates runs. Two successive plausible fixes recover
coverage, without a GPS chord across the missing interval.

For each gap, use calibration windows wholly contained in the immediately
preceding/following good runs and within 60 seconds of the gap boundaries. Take
a median on each side and interpolate length linearly across the gap. Integrate
this length over the step increments (uniform step rate between observations).
If only one side exists, use it throughout; if neither exists, use 0.75 m. Later
windows beyond that local neighborhood never change the gap. The ending gap
remains one-sided at test end. Without either GPS coverage or step-counter
coverage, add no distance and report uncovered duration. Zero recorded steps
mean covered but stationary; a counter reset interval is uncovered.

The live comparison diagnostics include GPS/step/default-length meters,
calibration windows, gaps, uncovered seconds and the signed correction relative
to using only preceding calibration. This correction is not the last UI update.
The comparison remains explicitly provisional. Replay plots the estimate known
at each event, not a hindsight-rewritten historical curve. There is no new
finalization API, reference-data input, persistence schema or primary-distance
change. The GPS edges use raw positions after quality checks, not Kalman output:
reported good accuracy can still permit stationary drift or corner cutting.

## Recorded-data benchmark

Reproduce from `tools/6mwt_data_visualizer`:

```sh
flutter test --no-pub test/gps_step_benchmark_test.dart --reporter expanded
```

Whole-recording totals (meters), 13 checked-in recordings:

| Recording | Raw GPS | Filtered GPS | Kalman | Fixed steps | Calibrated steps | Adaptive |
|---|---:|---:|---:|---:|---:|---:|
| Basauri | 548.5 | 532.9 | 520.6 | 488.3 | 535.4 | 545.6 |
| Gasteiz 1 | 589.8 | 589.8 | 588.0 | 475.5 | 588.8 | 596.5 |
| Gasteiz 2 | 623.3 | 623.3 | 622.6 | 510.0 | 624.8 | 628.4 |
| Wald 1 | 272.0 | 272.0 | 259.1 | 268.5 | 287.2 | 281.3 |
| Wald 2 | 324.2 | 324.2 | 303.7 | 287.3 | 300.0 | 323.3 |
| Wald 3 | 91.2 | 91.2 | 87.8 | 107.3 | 107.5 | 88.4 |
| Pletzia | 563.9 | 509.8 | 509.4 | 459.8 | 530.4 | 513.7 |
| Strand 1 | 509.6 | 97.8 | 90.3 | 123.0 | 123.2 | 118.8 |
| Strand 2 | 352.6 | 352.6 | 338.1 | 330.8 | 349.1 | 350.4 |
| Wanderung | 185.5 | 185.5 | 178.2 | 238.5 | 173.1 | 182.9 |
| Unterführung 1 | 558.3 | 504.8 | 500.1 | 498.8 | 460.9 | 460.4 |
| Unterführung 2 | 546.6 | 429.0 | 414.8 | 456.8 | 452.1 | 455.1 |
| Unterführung 3 | 263.5 | 263.2 | 256.4 | 230.3 | 220.5 | 227.0 |

Mean absolute percentage deviation on reference overlap (each reference equally
weighted; values are deviations from comparison recordings, not true errors):

| Reference | Raw GPS | Filtered GPS | Kalman | Fixed steps | Calibrated steps | Adaptive |
|---|---:|---:|---:|---:|---:|---:|
| Device (12) | 39.23% | 9.31% | 10.62% | 13.41% | 8.78% | 9.70% |
| Manual (3) | 17.46% | 8.90% | 8.62% | 1.86% | 2.54% | 1.57% |

The adaptive variant improves the three manual comparisons on average, especially
Unterführung 2/3, but is not uniformly better: Wald 3 and some device comparisons
remain poor. Calibrated steps have the lowest mean device-reference deviation in
this set. Different reference methods disagree, and these few recordings do not
establish clinical accuracy or justify changing the primary estimator. Overlap
metrics subtract the live estimate at each boundary; retrospective corrections
can include earlier periods, so these are operational live-curve comparisons,
not strictly isolated hindsight distance estimates inside the overlap.
