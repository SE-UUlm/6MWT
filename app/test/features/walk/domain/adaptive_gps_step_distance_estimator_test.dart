import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/adaptive_gps_step_distance_estimator.dart';
import 'calibrated_step_distance_estimator_test.dart' as f;

double meters(AdaptiveGpsStepDistanceEstimator e, String key) =>
    double.parse(e.additionalInfo[key]!.split(' ').first);

void main() {
  test('GPS replaces provisional steps without double counting', () {
    final e = AdaptiveGpsStepDistanceEstimator();
    e.addSample(f.gps(0, 0));
    e.addSample(f.steps(0, 0));
    e.addSample(f.steps(5, 10));
    expect(e.totalDistance, 7.5);
    e.addSample(f.gps(5, 5));
    expect(e.totalDistance, closeTo(5, .02));
    e.addSample(f.steps(10, 20));
    e.addSample(f.gps(10, 10));
    expect(e.totalDistance, closeTo(10, .03));
    expect(e.additionalInfo['Step distance'], '0.00 m');
  });

  test('gap interpolates different local lengths before and after', () {
    final e = AdaptiveGpsStepDistanceEstimator();
    // Before: 20m / 40 steps = .5m. Gap: 40 steps. After: 40m / 40 steps = 1m.
    for (var t = 0; t <= 60; t += 5) {
      e.addSample(f.steps(t.toDouble(), t * 2));
      if (t <= 20) e.addSample(f.gps(t.toDouble(), t.toDouble()));
      if (t == 25) e.addSample(f.gps(25, 25, accuracy: 50));
      if (t >= 40) e.addSample(f.gps(t.toDouble(), 40 + (t - 40) * 2));
      expect(e.totalDistance.isFinite, isTrue);
    }
    expect(e.totalDistance, closeTo(90, .3)); // 20 + 30 + 40
    expect(meters(e, 'Step distance'), closeTo(30, .1));
    expect(meters(e, 'Correction from following calibration'), closeTo(10, .1));
    expect(e.additionalInfo['Uncovered duration'], '0.0 s');
  });

  test('closed gap stops changing after its following sixty seconds', () {
    final e = AdaptiveGpsStepDistanceEstimator();
    String? frozenGap;
    for (var t = 0; t <= 160; t += 5) {
      e.addSample(f.steps(t.toDouble(), t * 2));
      if (t <= 20 || t >= 40) {
        final x = t <= 100 ? t.toDouble() : 100 + (t - 100) * 2.0;
        e.addSample(f.gps(t.toDouble(), x));
      }
      if (t == 100 || t == 160) {
        expect(meters(e, 'Step distance'), closeTo(20, .1));
        if (t == 100) frozenGap = e.additionalInfo['Step distance'];
        if (t == 160) expect(e.additionalInfo['Step distance'], frozenGap);
      }
    }
  });

  test(
    'initial gap uses following calibration; terminal gap uses preceding',
    () {
      final e = AdaptiveGpsStepDistanceEstimator();
      for (var t = 0; t <= 40; t += 5) {
        e.addSample(f.steps(t.toDouble(), t * 2));
        if (t >= 10 && t <= 30) e.addSample(f.gps(t.toDouble(), t.toDouble()));
      }
      expect(e.totalDistance, closeTo(40, .1));
      expect(e.additionalInfo['Default-length distance'], '0.00 m');
    },
  );

  test('neither sensor coverage is reported, not extrapolated', () {
    final e = AdaptiveGpsStepDistanceEstimator();
    e.addSample(f.gps(0, 0));
    e.addSample(f.gps(5, 5));
    e.addSample(f.gps(25, 25));
    expect(e.totalDistance, closeTo(5, .02));
    expect(e.additionalInfo['Uncovered duration'], '20.0 s');
    e.addSample(f.gps(30, 30));
    expect(e.totalDistance, closeTo(10, .03));
  });

  test('steps only, stops, counter resets and foreign sources', () {
    final e = AdaptiveGpsStepDistanceEstimator();
    for (final s in [
      f.steps(0, 100),
      f.steps(10, 120),
      f.steps(20, 120),
      f.steps(20, 1000),
      f.steps(25, 300, source: 'watch'),
      f.steps(30, 0),
      f.steps(40, 20),
    ]) {
      e.addSample(s);
    }
    expect(e.totalDistance, 30);
    expect(e.additionalInfo['Default-length distance'], '30.00 m');
    expect(e.additionalInfo['Uncovered duration'], '10.0 s');
    e.reset();
    expect(e.totalDistance, 0);
    expect(e.additionalInfo['GPS gaps'], '0');
  });

  test('shuttle turns and stops with good GPS use measured path', () {
    final e = AdaptiveGpsStepDistanceEstimator();
    for (var t = 0; t <= 60; t += 5) {
      final x = t <= 20
          ? t.toDouble()
          : t <= 40
          ? 20.0
          : 60.0 - t;
      e.addSample(f.gps(t.toDouble(), x));
      e.addSample(
        f.steps(
          t.toDouble(),
          (t <= 20
                  ? t
                  : t <= 40
                  ? 20
                  : t - 20) *
              2,
        ),
      );
    }
    expect(e.totalDistance, closeTo(40, .1));
    expect(e.additionalInfo['Step distance'], '0.00 m');
  });

  test('multiple gaps retain distinct neighboring calibration', () {
    final e = AdaptiveGpsStepDistanceEstimator();
    for (var t = 0; t <= 100; t += 5) {
      e.addSample(f.steps(t.toDouble(), t * 2));
      if (t <= 20 || (t >= 40 && t <= 60) || t >= 80) {
        e.addSample(f.gps(t.toDouble(), t.toDouble()));
      }
    }
    expect(e.totalDistance, closeTo(100, .3));
    expect(e.additionalInfo['GPS gaps'], '2');
    expect(meters(e, 'Step distance'), closeTo(40, .1));
  });
}
