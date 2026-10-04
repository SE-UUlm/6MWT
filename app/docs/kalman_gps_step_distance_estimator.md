# Kalman GPS + steps

`KalmanGpsStepDistanceEstimator` is an additional comparison estimator in the
app and visualizer. It does not replace the primary measurement automatically.

Steps provide distance, GPS estimates meters per step with a scalar Kalman
filter. This avoids integrating GPS jitter during measured pauses and lets
steps cover GPS outages and shuttle turns. Without steps, accepted GPS edges
provide a fallback. GPS and steps never both contribute to the same interval.

## Model

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

## Limits

This assumes roughly consistent step length within a session. Changing gait,
missed or spurious steps, frozen counters, sparse GPS hiding a turn, and systematic
GPS bias remain error sources. In poor GPS the default or last learned length is
used. Without either sensor's coverage, no distance is invented. GPS fallback
uses the shared accuracy/speed-gated polyline and can still accumulate drift.
No reference distance is used for calibration or parameter fitting.

## Existing recording comparison

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
