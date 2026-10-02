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
