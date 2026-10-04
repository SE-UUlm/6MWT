# Distance Estimators

This page collects the distance algorithms shared by the app and the Estimator
Lab, their configuration, limitations, benchmarks, and extension interface.
Paths and command working directories below are relative to the repository root.

## Contents

- [App integration](#app-integration)
- [Plain GPS](#plain-gps)
- [Filtered GPS](#filtered-gps)
- [Fixed steps](#fixed-steps)
- [GPS + steps and Lab variants](#gps--steps-and-lab-variants)
- [GPS-calibrated step comparisons](#gps-calibrated-step-comparisons)
- [Experimental GPS Kalman distance estimator](#experimental-gps-kalman-distance-estimator)
- [Kalman GPS + steps](#kalman-gps--steps)
- [Adding your own DistanceEstimator](#adding-your-own-distanceestimator)

## App integration

The session provider configures the primary `GpsStepDistanceEstimator` and additional
named estimators in `app/lib/features/walk/domain/walk_session_provider.dart`. Each
entry must own a separate estimator instance. All estimators receive the same
initial and live sensor samples, excluding warm-up samples.

The default comparisons are plain GPS, Kalman GPS + steps, adaptive GPS + steps,
calibrated steps, Kalman GPS, filtered GPS (maximum accuracy radius 20 m, maximum
speed 3 m/s), and steps (fixed step length 0.75 m). Their shared implementations
also power the data visualizer. Diagnostics appear below the detailed walking
view and between test details and profile information on the result screen,
including in release builds. A failed comparison is disabled until the next run.

Comparison results are kept in memory for the current test only. They survive
the session reset when navigating to its result, but are not stored in history
or JSON exports. The primary GPS/step distance remains the basis for assessment and
persistence.

## Plain GPS

`GpsDistanceEstimator` sums the geographic distance between consecutive position
samples with latitude and longitude. It is the original unfiltered GPS baseline
and is available as **Plain GPS** in the app's live comparisons.

## Filtered GPS

`FilteredGpsEstimator` rejects invalid coordinates, reported accuracy radii above
the threshold, nonpositive time intervals, and segment speeds above the threshold.
Rejected fixes do not become the next segment's anchor. Missing accuracy is
accepted. This simple filter can remain anchored at a bad first fix; it is a
development baseline.

## Fixed steps

`StepDistanceEstimator` multiplies cumulative step deltas by a fixed length.
It uses the first valid cumulative-step source, ignores status-only events, and
treats a counter decrease as a new baseline. No steps before the first sample
are inferred.

## GPS + steps and Lab variants

`GpsStepDistanceEstimator` combines accepted GPS segments with calibrated step
fallback and currently supplies the app's primary distance.

The GPS/step estimator has three Lab variants: maximum GPS intervals of **5, 10
and 15 seconds**. All three start step fallback after **5 seconds** without a
good fix. Later accepted GPS segments replace only their overlapping provisional
step distance and also contribute to stride calibration. Accuracy and speed
filters still apply; a rejected fix breaks the GPS segment. The main app keeps
its existing 5-second defaults.

Variant labels include the GPS interval limit. **Additional info** shows both
time limits, accepted GPS intervals, rejection counts for time gaps, coordinates,
accuracy and speed, and successful/rejected stride calibration windows. Successful
updates include the first learned stride and subsequent smoothed updates.

To compare all repository recordings with the same replay and reference alignment,
run from `tools/6mwt_data_visualizer`:

```bash
flutter test tool/compare_gps_gaps.dart --reporter expanded
```

This writes `build/gps_gap_comparison.md` and `build/gps_gap_comparison.json` with
per-recording diagnostics, reference deltas over shared time, and aggregate errors.
Watch measurements and manually drawn references are evaluated separately.

## GPS-calibrated step comparisons

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

### Local GPS/step fusion

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

### Recorded-data benchmark

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

## Experimental GPS Kalman distance estimator

`KalmanGpsDistanceEstimator` implements the existing `DistanceEstimator`
interface and runs as **Kalman GPS** in the live comparison and result screen.
The visualizer imports the same implementation. The `GpsStepDistanceEstimator` supplies the primary, persisted distance and
fitness assessment. Raw samples,
GPS acquisition settings, and database schemas are unchanged.

The intended first use is outdoor walking on free routes. No steps, inertial
measurements, altitude, watch reference, or wall-clock time enter the calculation.
The supplied location stream is used as-is; this does not force the operating
system's location provider to use satellite observations exclusively.

### Processing

1. Select the first source with a valid position and positive, finite accuracy.
   Ignore other sources and non-position samples. Reject invalid coordinates,
   missing/invalid accuracy, accuracy above the limit, and non-increasing times.
2. Check displacement against `maxSpeed × dt + previousAccuracy + accuracy`.
   Accuracy describes uncertainty, not a guaranteed bound. This deliberately
   avoids treating ordinary position noise as an impossible walking speed.
   Reported `speed` and `heading` are not used: the recorded schema does not
   include their uncertainty. There is no minimum walking speed veto.
3. Project positions onto a local spherical east/north tangent plane in meters
   (Earth radius 6,371,000 m). Maintain a constant-velocity state `[x, y, vx, vy]`.
   Independent x/vx and y/vy blocks share the same isotropic covariance, which is
   equivalent to the four-state block-diagonal filter. For each axis:
   `F = [[1, dt], [0, 1]]`,
   `Q = accelerationSigma² × [[dt⁴/4, dt³/2], [dt³/2, dt²]]`.
   Initial velocity is zero. Measurement variance per axis is
   `max(minPositionSigma, accuracy)²`: a conservative modeling choice, not an
   exact conversion of platform accuracy radii into Gaussian standard deviations.
4. Reject the measurement if its two-dimensional squared Mahalanobis innovation
   exceeds the configured threshold. Predict/update is speculative until the
   checks pass; rejected measurements never become filter or distance anchors.
   Covariance correction uses the Joseph form. Predictions alone add no meters.
5. Keep a separate distance anchor. Book the full displacement from that anchor
   only once it reaches `max(minDistance, accuracyDistanceFactor × accuracy)`.
   Then advance the anchor. This accumulates slow movement across samples rather
   than throwing away every small step. It also suppresses small stationary
   fluctuations. No accuracy radius is subtracted from booked meters.

### Gaps and recovery

After more than 15 seconds without an accepted measurement, require two new
quality-checked positions whose mutual displacement passes the speed check.
This also recovers from an initially incorrect fix that would otherwise prevent
all subsequent innovation checks from passing. Invalid quality interrupts the
candidate pair; an implausible second point becomes the next candidate.

On confirmation, connect the previous distance anchor to the first recovery
point exactly once, provided the old-to-new raw displacement is plausible.
Reinitialize the filter at the first recovery point and process the second point
without the stale innovation gate. If the two recovery points themselves are
more than 15 seconds apart, count their connection as another gap and initialize
at the second point, without extrapolating a long Kalman prediction.

Diagnostics distinguish confirmed gap duration, estimated straight-line gap
meters, rejected gap connections, and a still-pending recovery point. A rejected
gap connection does not prevent reacquisition at the confirmed new positions.
Pending final points do not contribute distance until confirmed. No distance is
inferred before the first fix or after the last fix.

### Configuration

Create an estimator with `KalmanGpsDistanceEstimator(config: KalmanGpsConfig(...))`.
All configuration fields are immutable; non-finite/nonpositive values are rejected
at construction (the accuracy distance factor may be zero). `reset()` clears all
run state, counters, selected source, and pending recovery, retaining configuration.

| Parameter | Default |
| --- | ---: |
| `maxAccuracy` | 20 m |
| `maxSpeed` | 4 m/s |
| `minPositionSigma` | 3 m |
| `initialVelocitySigma` | 2 m/s |
| `accelerationSigma` | 1.5 m/s² |
| `innovationThreshold` | 9.21 |
| `gapSeconds` | 15 s |
| `minDistance` | 5 m |
| `accuracyDistanceFactor` | 0.5 |

The planned 2 m distance threshold was increased to 5 m after the stationary
test (independent Gaussian noise, standard deviation 1 m per axis, reported
accuracy 3 m, seed 42) produced approximately 102 m at 1-second sampling and
71 m at 5-second sampling over six minutes. No reference recordings were used
to tune these defaults.

### Validation and reproducible benchmark

From `app/`, run:

```sh
flutter test --no-pub
flutter analyze --no-pub
```

From `tools/6mwt_data_visualizer/`, run:

```sh
flutter test --no-pub
flutter test --no-pub test/kalman_gps_benchmark_test.dart --reporter expanded
flutter analyze --no-pub
```

Synthetic six-minute tests cover 1- and 5-second sampling, straight walking at
0.3 and 1.4 m/s, pauses, a 30 m radius circle, 30 m shuttle legs with 180-degree
turns, and stationary/noisy walking traces. For independent Gaussian position
noise with standard deviation 1 m per axis and reported accuracy 3 m, seeds
7, 19, 42, 73, and 101 pass these bounds:

- Stationary: at most 5 m accumulated.
- Straight walking at 1.4 m/s: at most 5% error.
- Noisy walking at 0.3 m/s: at most 15% error (noiseless: at most 5%).
- Noiseless stop/go and circle: at most 5% error; shuttle turns: at most 15%.

Additional tests check a hand-calculated Kalman update, timestamp/coordinate/
accuracy rejection, independent speed and innovation checks, dateline crossing,
source selection, gaps, bad initialization, sparse recovery, reset determinism,
monotonicity, and identical live/direct/replay results. Raw outliers remain in
the sample sink while the comparison rejects them.

Recorded-data results for the 13 checked-in sessions (meters, whole replay):

| Session | Raw GPS | Simple filter | Kalman GPS |
| --- | ---: | ---: | ---: |
| Basauri (fehlende Uhraufzeichnung) | 548.5 | 532.9 | 520.6 |
| Gasteiz 1 | 589.8 | 589.8 | 588.0 |
| Gasteiz 2 | 623.3 | 623.3 | 622.6 |
| Gräfenberg Wald 1 | 272.0 | 272.0 | 259.1 |
| Gräfenberg Wald 2 | 324.2 | 324.2 | 303.7 |
| Gräfenberg Wald 3 | 91.2 | 91.2 | 87.8 |
| Pletzia | 563.9 | 509.8 | 509.4 |
| Pletzia Strand 1 | 509.6 | 97.8 | 90.3 |
| Pletzia Strand 2 | 352.6 | 352.6 | 338.1 |
| Pletzia Wanderung | 185.5 | 185.5 | 178.2 |
| Unterführung 1 | 558.3 | 504.8 | 500.1 |
| Unterführung 2 | 546.6 | 429.0 | 414.8 |
| Unterführung 3 | 263.5 | 263.2 | 256.4 |

The simple baseline uses `maxAccuracy: 20, maxSpeed: 3`. The benchmark computes
reference deltas only within each shared recording interval, using the existing
replay interpolation. Mean absolute percentage deviations, equally weighted per
reference, are:

| Reference type | Count | Raw GPS | Simple filter | Kalman GPS |
| --- | ---: | ---: | ---: | ---: |
| Device recordings | 12 | 39.23% | 9.31% | 10.62% |
| Manually drawn routes | 3 | 17.46% | 8.90% | 8.62% |

These comparisons do **not** demonstrate general superiority over the simple
filter. For example, the device-reference deviation in Gräfenberg Wald 2 falls
from +23.9 m to +3.3 m, but Gräfenberg Wald 1 changes from −36.0 m to −48.9 m.
Both reference types contain uncertainty; manually drawn routes assume constant
speed for partial-window comparisons. They are not ground truth or clinical
validation. The benchmark intentionally does not assert that Kalman must beat
the baseline on these recordings.

### Known limits

The distance threshold trades stationary drift against undercounting and delay.
The final subthreshold displacement is not flushed; tight turns may lose distance
repeatedly. Slowly correlated GPS drift can still be counted as movement, and
coherent multipath errors can pass the speed and innovation checks. The synthetic
noise tests do not model those effects. Short rejected intervals can be bridged
by the next accepted filtered position and also cut corners.

Long gaps have no recoverable route geometry: straight-line connections can miss
curves or movement that returns to the same point. Gaps still awaiting confirmation
at session end remain uncounted. The comparisons/diagnostics follow the existing
live-result lifecycle; they are not added to stored session history. With no valid
GPS, the comparison remains zero and its accepted count is zero, rather than
claiming a successfully measured stationary test.

The next evaluation should use separately measured outdoor routes, including
known stops and slow walking, across devices. Promotion to primary distance
requires a separate decision based on those measurements.

## Kalman GPS + steps

`KalmanGpsStepDistanceEstimator` is an additional comparison estimator in the
app and visualizer. It does not replace the primary measurement automatically.

Steps provide distance, GPS estimates meters per step with a scalar Kalman
filter. This avoids integrating GPS jitter during measured pauses and lets
steps cover GPS outages and shuttle turns. Without steps, accepted GPS edges
provide a fallback. GPS and steps never both contribute to the same interval.

### Model

- State: session step length `L`, initially `config.defaultLength` (0.75 m).
  Initial variance `P = 0.25² m²`.
- Measurement: GPS endpoint displacement divided by steps in the same window.
  Windows require continuous accepted GPS and step coverage, at least 10 s,
  8 steps, and displacement at least `max(10 m, 2 × endpoint sigma)`.
  Insufficient displacement may extend a straight window up to 20 s.
- Straightness: endpoint displacement / GPS polyline length >= 0.9.
  This rejects visible turns and noisy tracks. Consecutive windows skip an edge
  so they do not share a GPS endpoint.
- Prediction: `P' = min(0.25², P + elapsedSeconds × 0.0001)`.
- Measurement variance: `R = (accuracyStart² + accuracyEnd²) / steps² + 0.03²`,
  with each GPS accuracy floored at 1 m. Reported accuracy is only a heuristic
  sigma; the result is not a calibrated confidence interval.
- Reject lengths outside 0.15–1.6 m or residuals exceeding three model sigmas.
  Update with `K = P'/(P'+R)`, `L += K × residual`, `P = (1-K) × P'`.

The scalar update follows [Welch and Bishop's Kalman filter introduction](https://www.cs.unc.edu/~welch/media/pdf/kalman_intro.pdf).
The sensor model, gates and default parameters here are engineering assumptions.

The current length applies to all observed steps, including earlier ones; the
displayed distance can decrease after calibration. Late batches are matched by
sensor timestamps using uniform step rate within each batch. Calculations are
cached and replayed deterministically, independent of getter frequency or
interleaving between sensors. Each sensor's own samples must remain ordered.
Counter resets establish a new baseline; only one source per sensor is selected.

### Limits

This assumes roughly consistent step length within a session. Changing gait,
missed or spurious steps, frozen counters, sparse GPS hiding a turn, and systematic
GPS bias remain error sources. In poor GPS the default or last learned length is
used. Without either sensor's coverage, no distance is invented. GPS fallback
uses the shared accuracy/speed-gated polyline and can still accumulate drift.
No reference distance is used for calibration or parameter fitting.

### Existing recording comparison

Reproduce from `tools/6mwt_data_visualizer`:

```sh
flutter test test/gps_step_benchmark_test.dart --reporter expanded
```

Mean absolute percentage error on the reference overlap, rounded:

| Estimator | Device reference (12) | Manual reference (3) |
| --- | ---: | ---: |
| Raw GPS | 39.23% | 17.46% |
| GPS Kalman | 10.62% | 8.62% |
| Fixed steps | 13.41% | 1.86% |
| Calibrated steps | 8.78% | 2.54% |
| Adaptive GPS + steps | 9.70% | 1.57% |
| Kalman GPS + steps | 9.41% | 1.99% |

The new variant improves over GPS-only on average in these recordings but does
not consistently beat the other step-based estimators. Device references are
not ground truth; three manual references are insufficient to establish general
6MWT accuracy. Retain it as a comparison option pending more measured routes.

## Adding your own DistanceEstimator

Extend the app's `DistanceEstimator` (`totalDistance`, `addSample`, `reset`) using the app's `SensorSample` type. See `app/lib/features/walk/domain/experimental_estimators.dart` for the shared implementations. Keep algorithms independent of widgets, replay state and reference data.

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
