import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/kalman_gps_distance_estimator.dart';

SensorSample gps(
  double seconds,
  double x, {
  double y = 0,
  double? accuracy = 3,
  String source = 'gps',
}) => SensorSample(
  timestamp: DateTime.utc(
    2026,
  ).add(Duration(microseconds: (seconds * 1e6).round())),
  sourceId: source,
  type: SampleType.position,
  values: {
    PositionKeys.latitude: y / 6371000 * 180 / math.pi,
    PositionKeys.longitude: x / 6371000 * 180 / math.pi,
    PositionKeys.accuracy: ?accuracy,
  },
);

double run(
  KalmanGpsDistanceEstimator estimator,
  Iterable<SensorSample> samples,
) {
  var previous = estimator.totalDistance;
  for (final sample in samples) {
    estimator.addSample(sample);
    expect(estimator.totalDistance.isFinite, isTrue);
    expect(estimator.totalDistance, greaterThanOrEqualTo(previous));
    previous = estimator.totalDistance;
  }
  return previous;
}

void main() {
  test('validates configuration at runtime', () {
    for (final value in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => KalmanGpsConfig(maxSpeed: value), throwsArgumentError);
      expect(() => KalmanGpsConfig(gapSeconds: value), throwsArgumentError);
      expect(
        () => KalmanGpsConfig(accelerationSigma: value),
        throwsArgumentError,
      );
    }
    expect(
      () => KalmanGpsConfig(accuracyDistanceFactor: -1),
      throwsArgumentError,
    );
  });

  test('position correction agrees with the scalar Kalman equations', () {
    final estimator = KalmanGpsDistanceEstimator(
      config: KalmanGpsConfig(minDistance: 0.01, accuracyDistanceFactor: 0),
    );
    run(estimator, [gps(0, 0), gps(1, 8)]);
    // P(position) = 3² + 1² × 2² + 1.5² × 1⁴ / 4; R = 3².
    const predictedVariance = 13.5625;
    expect(
      estimator.totalDistance,
      closeTo(8 * predictedVariance / (predictedVariance + 9), 1e-6),
    );
  });

  test('invalid first source does not claim the clock or source', () {
    final estimator = KalmanGpsDistanceEstimator();
    run(estimator, [
      gps(1000, 0, accuracy: null, source: 'watch'),
      gps(0, 0),
      gps(5, 7),
    ]);
    expect(estimator.additionalInfo['GPS source'], 'gps');
    expect(estimator.totalDistance, greaterThan(5));
  });

  test('local projection crosses the dateline without a longitude jump', () {
    SensorSample point(double seconds, double longitude) => SensorSample(
      timestamp: DateTime.utc(2026).add(Duration(seconds: seconds.toInt())),
      type: SampleType.position,
      sourceId: 'gps',
      values: {
        PositionKeys.latitude: 0,
        PositionKeys.longitude: longitude,
        PositionKeys.accuracy: 3,
      },
    );
    final distance = run(KalmanGpsDistanceEstimator(), [
      point(0, 179.9999),
      point(5, -179.99999),
    ]);
    expect(distance, closeTo(12.23, 0.3));
  });

  for (final interval in [1, 5]) {
    for (final speed in [0.3, 1.4]) {
      test('six minute straight walk at $speed m/s, ${interval}s cadence', () {
        final estimator = KalmanGpsDistanceEstimator();
        final distance = run(estimator, [
          for (var t = 0; t <= 360; t += interval) gps(t.toDouble(), t * speed),
        ]);
        expect(distance, closeTo(360 * speed, 360 * speed * 0.05));
      });
    }
    for (final seed in [7, 19, 42, 73, 101]) {
      test(
        'six minute stationary Gaussian noise seed $seed, ${interval}s cadence',
        () {
          final random = math.Random(seed);
          double noise() =>
              math.sqrt(-2 * math.log(1 - random.nextDouble())) *
              math.cos(2 * math.pi * random.nextDouble());
          final distance = run(KalmanGpsDistanceEstimator(), [
            for (var t = 0; t <= 360; t += interval)
              gps(t.toDouble(), noise(), y: noise()),
          ]);
          expect(distance, lessThanOrEqualTo(5));
        },
      );
      test('noisy straight walk seed $seed, ${interval}s cadence', () {
        final random = math.Random(seed);
        double noise() =>
            math.sqrt(-2 * math.log(1 - random.nextDouble())) *
            math.cos(2 * math.pi * random.nextDouble());
        final distance = run(KalmanGpsDistanceEstimator(), [
          for (var t = 0; t <= 360; t += interval)
            gps(t.toDouble(), t * 1.4 + noise(), y: noise()),
        ]);
        expect(distance, closeTo(504, 504 * 0.05));
      });
      test('noisy slow walk seed $seed, ${interval}s cadence', () {
        final random = math.Random(seed);
        double noise() =>
            math.sqrt(-2 * math.log(1 - random.nextDouble())) *
            math.cos(2 * math.pi * random.nextDouble());
        final distance = run(KalmanGpsDistanceEstimator(), [
          for (var t = 0; t <= 360; t += interval)
            gps(t.toDouble(), t * 0.3 + noise(), y: noise()),
        ]);
        expect(distance, closeTo(108, 108 * 0.15));
      });
    }
    test(
      'stop and go does not integrate predictions, ${interval}s cadence',
      () {
        final estimator = KalmanGpsDistanceEstimator();
        final distance = run(estimator, [
          for (var t = 0; t <= 360; t += interval)
            gps(
              t.toDouble(),
              t <= 120
                  ? t * 1.4
                  : t <= 240
                  ? 168
                  : 168 + (t - 240) * 1.4,
            ),
        ]);
        expect(distance, closeTo(336, 336 * 0.05));
      },
    );
    test('circle retains distance, ${interval}s cadence', () {
      const radius = 30.0;
      final distance = run(KalmanGpsDistanceEstimator(), [
        for (var t = 0; t <= 360; t += interval)
          gps(
            t.toDouble(),
            radius * math.cos(t * 1.2 / radius),
            y: radius * math.sin(t * 1.2 / radius),
          ),
      ]);
      expect(distance, closeTo(432, 432 * 0.05));
    });
    test(
      '180 degree turns recover without locking out, ${interval}s cadence',
      () {
        final estimator = KalmanGpsDistanceEstimator();
        final distance = run(estimator, [
          for (var t = 0; t <= 360; t += interval)
            gps(t.toDouble(), 30 - ((t % 60) - 30).abs().toDouble()),
        ]);
        expect(distance, closeTo(360, 360 * 0.15));
        expect(estimator.additionalInfo['GPS gaps'], '0');
      },
    );
  }

  test('outlier does not create an outward and return jump', () {
    final clean = KalmanGpsDistanceEstimator();
    final dirty = KalmanGpsDistanceEstimator();
    final samples = [gps(0, 0), gps(5, 7), gps(10, 14), gps(15, 21)];
    run(clean, samples);
    run(dirty, [samples[0], samples[1], gps(7, 1000), samples[2], samples[3]]);
    expect(dirty.totalDistance, clean.totalDistance);
    expect(dirty.additionalInfo['Rejected: speed'], '1');
  });

  test(
    'innovation rejects a jump that passes uncertainty-aware speed gate',
    () {
      final estimator = KalmanGpsDistanceEstimator(
        config: KalmanGpsConfig(innovationThreshold: 1),
      );
      run(estimator, [for (var t = 0; t <= 10; t++) gps(t.toDouble(), 0)]);
      // Eight meters in one second passes the 4 m/s + 6 m uncertainty gate,
      // but violates this deliberately tighter innovation gate.
      estimator.addSample(gps(11, 8));
      expect(estimator.additionalInfo['Rejected: innovation'], '1');
    },
  );

  test('invalid inputs and unrelated sources do not change distance', () {
    final estimator = KalmanGpsDistanceEstimator();
    run(estimator, [gps(0, 0), gps(5, 7)]);
    final distance = estimator.totalDistance;
    run(estimator, [
      gps(5, 30),
      gps(4, 30),
      gps(6, double.nan),
      gps(7, 0, accuracy: null),
      gps(8, 0, accuracy: 0),
      gps(9, 0, accuracy: -1),
      gps(10, 0, accuracy: double.infinity),
      gps(11, 0, accuracy: 21),
      gps(12, 100, source: 'watch'),
      SensorSample(
        timestamp: DateTime.utc(2026),
        sourceId: 'steps',
        type: SampleType.steps,
        values: {StepKeys.cumulativeSteps: 500},
      ),
    ]);
    expect(estimator.totalDistance, distance);
    expect(estimator.additionalInfo['Rejected: timestamp'], '2');
    expect(estimator.additionalInfo['Rejected: accuracy'], '5');
  });

  test('gap needs confirmation and is bridged exactly once', () {
    final estimator = KalmanGpsDistanceEstimator();
    estimator.addSample(gps(0, 0));
    estimator.addSample(gps(20, 20));
    expect(estimator.totalDistance, 0);
    expect(estimator.additionalInfo['Recovery pending'], 'true');
    estimator.addSample(gps(25, 25));
    // The confirmed point adds just under 5 m after smoothing: retain that
    // remainder at the anchor until a later point crosses the deadband.
    expect(estimator.totalDistance, closeTo(20, 0.2));
    expect(estimator.additionalInfo['GPS gaps'], '1');
    expect(estimator.additionalInfo['Gap duration'], '20.0 s');
    expect(
      estimator.additionalInfo['Gap distance (straight-line estimate)'],
      '20.0 m',
    );
    estimator.addSample(gps(30, 30));
    expect(estimator.totalDistance, closeTo(30, 0.2));
    expect(estimator.additionalInfo['GPS gaps'], '1');
  });

  test('bad initial fix recovers without booking impossible bridge', () {
    final estimator = KalmanGpsDistanceEstimator();
    run(estimator, [
      gps(0, 1000),
      gps(5, 5),
      gps(10, 10),
      gps(16, 16),
      gps(21, 21),
    ]);
    expect(estimator.totalDistance, 0);
    expect(estimator.additionalInfo['Rejected gap connections'], '1');
    estimator.addSample(gps(26, 26));
    expect(estimator.totalDistance, closeTo(10, 0.2));
  });

  test('bad recovery candidates cannot independently add distance', () {
    final estimator = KalmanGpsDistanceEstimator();
    run(estimator, [gps(0, 0), gps(20, 1000), gps(25, 25)]);
    expect(estimator.totalDistance, 0);
    estimator.addSample(gps(30, 30, accuracy: 100));
    estimator.addSample(gps(35, 35));
    expect(estimator.totalDistance, 0);
    estimator.addSample(gps(40, 40));
    expect(estimator.totalDistance, closeTo(35, 0.2));
    estimator.addSample(gps(45, 45));
    expect(estimator.totalDistance, closeTo(45, 0.2));
    expect(estimator.additionalInfo['GPS gaps'], '1');
  });

  test(
    'sparse confirmed samples bridge both long intervals without prediction',
    () {
      final estimator = KalmanGpsDistanceEstimator();
      run(estimator, [gps(0, 0), gps(20, 20), gps(40, 40)]);
      expect(estimator.totalDistance, closeTo(40, 0.01));
      expect(estimator.additionalInfo['GPS gaps'], '2');
      expect(estimator.additionalInfo['Gap duration'], '40.0 s');
      expect(
        estimator.additionalInfo['Gap distance (straight-line estimate)'],
        '40.0 m',
      );
      estimator.addSample(gps(60, 60));
      expect(estimator.totalDistance, closeTo(40, 0.01));
      estimator.addSample(gps(80, 80));
      expect(estimator.totalDistance, closeTo(80, 0.01));
    },
  );

  test('reset clears every run state and replay is deterministic', () {
    final estimator = KalmanGpsDistanceEstimator();
    final freshInfo = estimator.additionalInfo;
    final samples = [
      gps(0, 0),
      gps(5, 7),
      gps(7, 1000),
      gps(30, 40),
      gps(35, 47),
    ];
    final distance = run(estimator, samples);
    final diagnostics = estimator.additionalInfo;
    estimator.reset();
    expect(estimator.totalDistance, 0);
    expect(estimator.additionalInfo, freshInfo);
    expect(run(estimator, samples), distance);
    expect(estimator.additionalInfo, diagnostics);
  });
}
