# Experimental GPS Kalman distance estimator

`KalmanGpsDistanceEstimator` implements the existing `DistanceEstimator`
interface and runs as **Kalman GPS** in the live comparison and result screen.
The visualizer imports the same implementation. The original `GpsDistanceEstimator`
still supplies the primary, persisted distance and fitness assessment. Raw samples,
GPS acquisition settings, and database schemas are unchanged.

The intended first use is outdoor walking on free routes. No steps, inertial
measurements, altitude, watch reference, or wall-clock time enter the calculation.
The supplied location stream is used as-is; this does not force the operating
system's location provider to use satellite observations exclusively.

## Processing

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

## Gaps and recovery

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

## Configuration

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

## Validation and reproducible benchmark

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

## Known limits

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
