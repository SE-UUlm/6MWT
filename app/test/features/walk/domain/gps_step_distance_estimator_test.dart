import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/gps_step_distance_estimator.dart';

final _epoch = DateTime.utc(2026);
// Match the geodesic model of the existing GPS implementation.
final _metresPerDegree = Geolocator.distanceBetween(0, 0, 0, 1);

SensorSample _gps(int second, double metres, {double? accuracy = 3}) =>
    SensorSample(
      timestamp: _epoch.add(Duration(seconds: second)),
      sourceId: 'gps',
      type: SampleType.position,
      values: {
        PositionKeys.latitude: 0,
        PositionKeys.longitude: metres / _metresPerDegree,
        PositionKeys.accuracy: ?accuracy,
      },
    );

SensorSample _steps(int second, double count, {String source = 'pedometer'}) =>
    SensorSample(
      timestamp: _epoch.add(Duration(seconds: second)),
      sourceId: source,
      type: SampleType.steps,
      values: {StepKeys.cumulativeSteps: count},
    );

// The baseline at second zero is deliberately a nonzero boot counter.
void _walk(
  GpsStepDistanceEstimator estimator, {
  int start = 0,
  int seconds = 15,
  double metresPerSecond = 1,
  double initialMetres = 0,
  int initialSteps = 1000,
  bool stepsFirst = false,
}) {
  for (var i = 0; i <= seconds; i++) {
    final gps = _gps(start + i, initialMetres + i * metresPerSecond);
    final steps = _steps(start + i, (initialSteps + i).toDouble());
    for (final sample in stepsFirst ? [steps, gps] : [gps, steps]) {
      estimator.addSample(sample);
    }
  }
}

void main() {
  late GpsStepDistanceEstimator estimator;
  setUp(() {
    estimator = GpsStepDistanceEstimator(stepSourceId: 'pedometer');
  });

  test('good GPS supplies distance even without a step sensor', () {
    for (var i = 0; i <= 20; i++) {
      estimator.addSample(_gps(i, i.toDouble()));
    }
    expect(estimator.totalDistance, closeTo(20, 1e-6));
    expect(estimator.hasLearnedStepLength, isFalse);
  });

  for (final gap in [5, 10, 15]) {
    test('accepts the $gap s GPS boundary and rejects a longer gap', () {
      estimator = GpsStepDistanceEstimator(
        stepSourceId: 'pedometer',
        maxGpsInterval: Duration(seconds: gap),
      );
      estimator.addSample(_gps(0, 0));
      estimator.addSample(_gps(gap, gap.toDouble()));
      expect(estimator.totalDistance, closeTo(gap, 1e-6));
      estimator.addSample(_gps(2 * gap + 1, (2 * gap + 1).toDouble()));
      expect(estimator.totalDistance, closeTo(gap, 1e-6));
      expect(estimator.additionalInfo['Accepted GPS intervals'], '1');
      expect(estimator.additionalInfo['Rejected GPS gap'], '1');
    });
  }

  for (final stepsFirst in [false, true]) {
    test('late sparse GPS replaces fallback with stepsFirst=$stepsFirst', () {
      estimator = GpsStepDistanceEstimator(
        stepSourceId: 'pedometer',
        maxGpsInterval: const Duration(seconds: 10),
      );
      estimator.addSample(_gps(0, 0));
      estimator.addSample(_steps(0, 1000));
      estimator.addSample(_steps(5, 1005));
      expect(estimator.totalDistance, 0);
      estimator.addSample(_steps(6, 1006));
      expect(estimator.totalDistance, closeTo(4.2, 1e-6));
      for (final sample
          in stepsFirst
              ? [_steps(10, 1010), _gps(10, 8)]
              : [_gps(10, 8), _steps(10, 1010)]) {
        estimator.addSample(sample);
      }
      expect(estimator.totalDistance, closeTo(8, 1e-6));
      expect(estimator.hasLearnedStepLength, isFalse);
      estimator.addSample(_steps(16, 1016));
      expect(estimator.totalDistance, closeTo(8 + 6 * 0.7, 1e-6));
      estimator.addSample(_gps(20, 16));
      estimator.addSample(_steps(20, 1020));
      expect(estimator.hasLearnedStepLength, isTrue);
      expect(estimator.stepLength, closeTo(0.8, 1e-6));
      expect(estimator.totalDistance, closeTo(16, 1e-6));
      expect(estimator.additionalInfo['Calibration updates'], '1');
      expect(estimator.additionalInfo['Step distance'], '0.00 m');
    });
  }

  test('GPS can lower a provisional step estimate without double counting', () {
    estimator = GpsStepDistanceEstimator(
      stepSourceId: 'pedometer',
      maxGpsInterval: const Duration(seconds: 15),
    );
    estimator.addSample(_gps(0, 0));
    estimator.addSample(_steps(0, 1000));
    estimator.addSample(_steps(14, 1014));
    expect(estimator.totalDistance, closeTo(9.8, 1e-6));
    estimator.addSample(_gps(15, 8));
    estimator.addSample(_steps(15, 1015));
    expect(estimator.totalDistance, closeTo(8, 1e-6));
    expect(estimator.hasLearnedStepLength, isFalse); // Still below 10 m.
  });

  test('fallback timeout can be configured independently of GPS intervals', () {
    estimator = GpsStepDistanceEstimator(
      stepSourceId: 'pedometer',
      gpsFallbackTimeout: const Duration(seconds: 2),
      maxGpsInterval: const Duration(seconds: 10),
    );
    estimator.addSample(_gps(0, 0));
    estimator.addSample(_steps(0, 1000));
    estimator.addSample(_steps(2, 1002));
    expect(estimator.totalDistance, 0);
    estimator.addSample(_steps(3, 1003));
    expect(estimator.totalDistance, closeTo(2.1, 1e-6));
    estimator.addSample(_gps(10, 10));
    estimator.addSample(_steps(10, 1010));
    expect(estimator.totalDistance, closeTo(10, 1e-6));
  });

  test(
    'excessive gaps preserve steps and break sparse calibration windows',
    () {
      estimator = GpsStepDistanceEstimator(
        stepSourceId: 'pedometer',
        maxGpsInterval: const Duration(seconds: 15),
      );
      estimator.addSample(_gps(0, 0));
      estimator.addSample(_steps(0, 1000));
      estimator.addSample(_gps(10, 10));
      estimator.addSample(_steps(10, 1010));
      estimator.addSample(_steps(100, 1100));
      expect(estimator.totalDistance, closeTo(10 + 90 * 0.7, 1e-6));
      estimator.addSample(_gps(100, 100));
      estimator.addSample(_gps(110, 110));
      estimator.addSample(_steps(110, 1110));
      expect(estimator.totalDistance, closeTo(20 + 90 * 0.7, 1e-6));
      expect(estimator.hasLearnedStepLength, isFalse);
      expect(estimator.additionalInfo['Rejected GPS gap'], '1');
    },
  );

  test('longer GPS intervals still reject bad accuracy and speed', () {
    estimator = GpsStepDistanceEstimator(
      stepSourceId: 'pedometer',
      maxGpsInterval: const Duration(seconds: 15),
    );
    estimator.addSample(_gps(0, 0));
    estimator.addSample(_steps(0, 1000));
    estimator.addSample(_gps(10, 10, accuracy: 50));
    estimator.addSample(_steps(10, 1010));
    estimator.addSample(_gps(20, 20));
    estimator.addSample(_steps(20, 1020));
    estimator.addSample(_gps(30, 100));
    estimator.addSample(_steps(30, 1030));
    expect(estimator.totalDistance, closeTo(30 * 0.7, 1e-6));
    expect(estimator.hasLearnedStepLength, isFalse);
    expect(estimator.additionalInfo['Accepted GPS intervals'], '0');
    expect(estimator.additionalInfo['Rejected GPS accuracy'], '1');
    expect(estimator.additionalInfo['Rejected GPS speed'], '1');
  });

  test('diagnostics reset while configured time limits remain', () {
    estimator = GpsStepDistanceEstimator(
      stepSourceId: 'pedometer',
      maxGpsInterval: const Duration(seconds: 15),
    );
    _walk(estimator);
    estimator.addSample(_gps(16, 16, accuracy: 50));
    expect(estimator.additionalInfo['Calibration updates'], '1');
    expect(estimator.additionalInfo['Rejected GPS accuracy'], '1');
    estimator.reset();
    expect(estimator.additionalInfo['Max GPS interval'], '15.0 s');
    expect(estimator.additionalInfo['GPS fallback timeout'], '5.0 s');
    for (final key in [
      'Accepted GPS intervals',
      'Rejected GPS gap',
      'Rejected GPS coordinates',
      'Rejected GPS accuracy',
      'Rejected GPS speed',
      'Calibration updates',
      'Rejected calibration',
    ]) {
      expect(estimator.additionalInfo[key], '0', reason: key);
    }
  });

  test('rejects nonpositive time limits', () {
    for (final duration in [Duration.zero, const Duration(seconds: -1)]) {
      expect(
        () => GpsStepDistanceEstimator(
          stepSourceId: 'pedometer',
          maxGpsInterval: duration,
        ),
        throwsArgumentError,
      );
      expect(
        () => GpsStepDistanceEstimator(
          stepSourceId: 'pedometer',
          gpsFallbackTimeout: duration,
        ),
        throwsArgumentError,
      );
    }
  });

  for (final stepsFirst in [false, true]) {
    test('learns from aligned data with stepsFirst=$stepsFirst', () {
      _walk(estimator, stepsFirst: stepsFirst);
      expect(estimator.totalDistance, closeTo(15, 1e-6));
      expect(estimator.hasLearnedStepLength, isTrue);
      expect(estimator.stepLength, closeTo(1, 1e-6));

      estimator.addSample(_gps(16, 500, accuracy: 50));
      estimator.addSample(_steps(16, 1017));
      expect(estimator.totalDistance, closeTo(17, 1e-6));
    });
  }

  test('requires all three calibration minima', () {
    _walk(estimator, seconds: 14);
    expect(estimator.hasLearnedStepLength, isFalse);
    estimator.addSample(_gps(15, 15));
    estimator.addSample(_steps(15, 1015));
    expect(estimator.hasLearnedStepLength, isTrue);

    estimator.reset();
    estimator.addSample(_steps(0, 1000));
    for (var i = 0; i <= 15; i++) {
      estimator.addSample(_gps(i, i.toDouble()));
    }
    estimator.addSample(_steps(15, 1009));
    expect(estimator.hasLearnedStepLength, isFalse);

    estimator.reset();
    _walk(estimator, seconds: 19, metresPerSecond: 0.5);
    expect(estimator.hasLearnedStepLength, isFalse);
    estimator.addSample(_gps(20, 10));
    estimator.addSample(_steps(20, 1020));
    expect(estimator.hasLearnedStepLength, isTrue);
    expect(estimator.stepLength, closeTo(0.5, 1e-6));
  });

  test('smooths subsequent independent calibration windows', () {
    _walk(estimator, metresPerSecond: 0.8);
    expect(estimator.stepLength, closeTo(0.8, 1e-6));
    _walk(estimator, start: 15, initialMetres: 12, initialSteps: 1015);
    expect(estimator.stepLength, closeTo(0.84, 1e-6));
    _walk(estimator, start: 30, initialMetres: 27, initialSteps: 1030);
    expect(estimator.stepLength, closeTo(0.872, 1e-6));
    expect(estimator.totalDistance, closeTo(42, 1e-6));
    estimator.addSample(_gps(46, 42, accuracy: 50));
    estimator.addSample(_steps(46, 1047));
    expect(estimator.totalDistance, closeTo(42 + 2 * 0.872, 1e-6));
  });

  test(
    'learns with ten batched steps and fifteen seconds above the distance minimum',
    () {
      estimator.addSample(_steps(0, 1000));
      // Five GPS intervals divide the batch into exactly two steps each.
      for (var i = 0; i <= 15; i += 3) {
        estimator.addSample(_gps(i, i * 10.1 / 15));
      }
      estimator.addSample(_steps(15, 1010));
      expect(estimator.hasLearnedStepLength, isTrue);
      expect(estimator.stepLength, closeTo(1.01, 1e-6));
      expect(estimator.totalDistance, closeTo(10.1, 1e-6));
    },
  );

  test('a GPS distance just below ten metres does not trigger calibration', () {
    estimator.addSample(_steps(0, 1000));
    for (var i = 0; i <= 15; i += 3) {
      estimator.addSample(_gps(i, i * 9.9999999995 / 15));
    }
    estimator.addSample(_steps(15, 1010));
    expect(estimator.totalDistance, lessThan(10));
    expect(estimator.hasLearnedStepLength, isFalse);

    estimator.addSample(_gps(16, 10.1));
    estimator.addSample(_steps(16, 1011));
    expect(estimator.hasLearnedStepLength, isTrue);
    expect(estimator.stepLength, closeTo(10.1 / 11, 1e-6));
  });

  for (final stride in [0.1, 0.2, 1.5]) {
    test('accepts a positive stride of $stride metres', () {
      _walk(
        estimator,
        seconds: stride == 0.1 ? 101 : 50,
        metresPerSecond: stride,
      );
      expect(estimator.hasLearnedStepLength, isTrue);
      expect(estimator.stepLength, closeTo(stride, 1e-6));
    });
  }

  test('accepts a positive stride below the former lower bound', () {
    estimator.addSample(_steps(0, 1000));
    for (var i = 0; i <= 15; i++) {
      estimator.addSample(_gps(i, i * 10 / 15));
    }
    estimator.addSample(_steps(15, 2000));
    expect(estimator.hasLearnedStepLength, isTrue);
    expect(estimator.stepLength, closeTo(0.01, 1e-9));
  });

  test('zero GPS movement cannot become a learned zero stride', () {
    _walk(estimator, seconds: 30, metresPerSecond: 0);
    expect(estimator.hasLearnedStepLength, isFalse);
    expect(estimator.stepLength, 0.7);
    expect(estimator.totalDistance, 0);
  });

  test('uses only new phone steps with the default before calibration', () {
    estimator.addSample(_steps(0, 9000));
    expect(estimator.totalDistance, 0);
    estimator.addSample(_gps(0, 0, accuracy: 50));
    estimator.addSample(_steps(2, 9004));
    estimator.addSample(_steps(3, 9004));
    estimator.addSample(_steps(4, 99000, source: 'watch'));
    expect(estimator.totalDistance, closeTo(2.8, 1e-6));
    expect(estimator.stepLength, 0.7);
  });

  for (final stride in [0.6, 1.0]) {
    test('corrects earlier default distance once to $stride m per step', () {
      estimator.addSample(_steps(0, 1000));
      estimator.addSample(_steps(10, 1010));
      expect(estimator.totalDistance, closeTo(7, 1e-6));

      final calibrationSeconds = stride == 0.6 ? 17 : 15;
      _walk(
        estimator,
        start: 10,
        seconds: calibrationSeconds,
        initialSteps: 1010,
        metresPerSecond: stride,
      );
      expect(estimator.stepLength, closeTo(stride, 1e-6));
      final calibratedDistance = (10 + calibrationSeconds) * stride;
      expect(estimator.totalDistance, closeTo(calibratedDistance, 1e-6));

      // Further learning changes the current stride, but not historic fallback.
      _walk(
        estimator,
        start: 10 + calibrationSeconds,
        initialSteps: 1010 + calibrationSeconds,
        initialMetres: calibrationSeconds * stride,
        metresPerSecond: 1.2,
      );
      expect(
        estimator.stepLength,
        closeTo(stride + 0.2 * (1.2 - stride), 1e-6),
      );
      expect(estimator.totalDistance, closeTo(calibratedDistance + 18, 1e-6));
    });
  }

  test('GPS recovery does not bridge or recount fallback distance', () {
    _walk(estimator);
    estimator.addSample(_gps(16, 1000, accuracy: 30));
    estimator.addSample(_steps(18, 1018));
    expect(estimator.totalDistance, closeTo(18, 1e-6));
    estimator.addSample(_gps(20, 100));
    estimator.addSample(_steps(20, 1020));
    expect(estimator.totalDistance, closeTo(20, 1e-6));
    estimator.addSample(_gps(21, 101));
    estimator.addSample(_steps(21, 1021));
    expect(estimator.totalDistance, closeTo(21, 1e-6));
  });

  test(
    'splits a delayed step batch at GPS recovery without double counting',
    () {
      estimator.addSample(_steps(0, 1000));
      estimator.addSample(_gps(0, 0, accuracy: 50));
      estimator.addSample(_gps(5, 5));
      for (var i = 6; i <= 10; i++) {
        estimator.addSample(_gps(i, i.toDouble()));
      }
      estimator.addSample(_steps(10, 1010));
      // Five steps before recovery, then five metres measured by GPS.
      expect(estimator.totalDistance, closeTo(3.5 + 5, 1e-6));
      expect(estimator.hasLearnedStepLength, isFalse);
    },
  );

  test('late GPS replaces only steps belonging to its accepted intervals', () {
    estimator.addSample(_steps(0, 1000));
    estimator.addSample(_steps(10, 1010));
    expect(estimator.totalDistance, closeTo(7, 1e-6));
    for (var i = 5; i <= 10; i++) {
      estimator.addSample(_gps(i, i.toDouble()));
    }
    expect(estimator.totalDistance, closeTo(8.5, 1e-6));
  });

  test('missing GPS triggers fallback and recovery starts a new segment', () {
    estimator.addSample(_steps(0, 1000));
    estimator.addSample(_gps(0, 0));
    estimator.addSample(_steps(3, 1003));
    expect(estimator.totalDistance, 0); // Wait for a still-fresh GPS fix.
    estimator.addSample(_steps(6, 1006));
    expect(estimator.totalDistance, closeTo(4.2, 1e-6));
    estimator.addSample(_gps(7, 70));
    estimator.addSample(_steps(7, 1007));
    expect(estimator.totalDistance, closeTo(4.9, 1e-6));
    estimator.addSample(_gps(8, 71));
    estimator.addSample(_steps(8, 1008));
    expect(estimator.totalDistance, closeTo(5.9, 1e-6));
  });

  test('rejects position jumps without using them as the next anchor', () {
    estimator.addSample(_gps(0, 0));
    estimator.addSample(_steps(0, 1000));
    estimator.addSample(_gps(1, 100));
    estimator.addSample(_steps(1, 1001));
    expect(estimator.totalDistance, closeTo(0.7, 1e-6));
    estimator.addSample(_gps(2, 2));
    estimator.addSample(_steps(2, 1002));
    estimator.addSample(_gps(3, 3));
    estimator.addSample(_steps(3, 1003));
    expect(estimator.totalDistance, closeTo(2.4, 1e-6));
  });

  for (final accuracy in <double?>[null, -1, double.nan, double.infinity, 11]) {
    test('unusable accuracy $accuracy selects step fallback', () {
      estimator.addSample(_gps(0, 0));
      estimator.addSample(_steps(0, 1000));
      estimator.addSample(_gps(1, 1, accuracy: accuracy));
      estimator.addSample(_steps(1, 1001));
      expect(estimator.totalDistance, closeTo(0.7, 1e-6));
    });
  }

  test('invalid coordinates cannot poison distance or calibration', () {
    for (final coordinates in [
      <String, double>{},
      {PositionKeys.latitude: double.nan, PositionKeys.longitude: 0.0},
      {PositionKeys.latitude: 91.0, PositionKeys.longitude: 0.0},
      {PositionKeys.latitude: 0.0, PositionKeys.longitude: double.infinity},
      {PositionKeys.latitude: 0.0, PositionKeys.longitude: 181.0},
    ]) {
      estimator.reset();
      estimator.addSample(_steps(0, 1000));
      estimator.addSample(_gps(0, 0));
      estimator.addSample(
        SensorSample(
          timestamp: _epoch.add(const Duration(seconds: 1)),
          type: SampleType.position,
          sourceId: 'gps',
          values: {...coordinates, PositionKeys.accuracy: 1},
        ),
      );
      estimator.addSample(_steps(1, 1001));
      expect(estimator.totalDistance, closeTo(0.7, 1e-6));
    }
  });

  test('rejects a stride above the upper bound and can learn later', () {
    _walk(estimator, seconds: 120, metresPerSecond: 2);
    expect(estimator.hasLearnedStepLength, isFalse);
    expect(estimator.stepLength, 0.7);
    estimator.addSample(_gps(121, 0, accuracy: 50));
    _walk(estimator, start: 122, initialSteps: 1122);
    expect(estimator.hasLearnedStepLength, isTrue);
    expect(estimator.stepLength, closeTo(1, 1e-6));
  });

  test('an implausible update preserves the already learned stride', () {
    _walk(estimator);
    _walk(
      estimator,
      start: 15,
      initialMetres: 15,
      initialSteps: 1015,
      metresPerSecond: 2,
    );
    expect(estimator.hasLearnedStepLength, isTrue);
    expect(estimator.stepLength, closeTo(1, 1e-6));
  });

  test('disconnected short good GPS windows do not train a stride', () {
    _walk(estimator, seconds: 10);
    estimator.addSample(_gps(11, 0, accuracy: 50));
    _walk(estimator, start: 12, seconds: 10, initialSteps: 1012);
    expect(estimator.hasLearnedStepLength, isFalse);
    _walk(
      estimator,
      start: 22,
      seconds: 5,
      initialMetres: 10,
      initialSteps: 1022,
    );
    expect(estimator.stepLength, closeTo(1, 1e-6));
    expect(estimator.hasLearnedStepLength, isTrue);
  });

  test('GPS before a step baseline does not contribute to learning', () {
    for (var i = 0; i < 30; i++) {
      estimator.addSample(_gps(i, i.toDouble()));
    }
    _walk(estimator, start: 30, seconds: 10, initialMetres: 30);
    expect(estimator.hasLearnedStepLength, isFalse);
    _walk(
      estimator,
      start: 40,
      seconds: 5,
      initialMetres: 40,
      initialSteps: 1010,
    );
    expect(estimator.stepLength, closeTo(1, 1e-6));
  });

  test('counter reset and invalid or stale readings do not invent steps', () {
    estimator.addSample(_steps(0, 1000));
    estimator.addSample(_steps(1, 1002));
    estimator.addSample(_steps(2, 0));
    estimator.addSample(_steps(3, 3));
    estimator.addSample(_steps(3, 10)); // Duplicate timestamp.
    estimator.addSample(_steps(1, 10000)); // Out of order.
    for (final value in [double.nan, double.infinity, -1.0, 3.5]) {
      estimator.addSample(_steps(4, value));
    }
    estimator.addSample(
      SensorSample(
        timestamp: _epoch.add(const Duration(seconds: 4)),
        sourceId: 'pedometer',
        type: SampleType.steps,
        values: const {StepKeys.pedestrianStatus: 1},
      ),
    );
    estimator.addSample(_steps(5, 4));
    expect(estimator.totalDistance, closeTo(6 * 0.7, 1e-6));
  });

  test('stale GPS cannot break the current good segment', () {
    _walk(estimator, seconds: 5);
    estimator.addSample(_gps(4, 500, accuracy: 50));
    estimator.addSample(_gps(5, 500));
    estimator.addSample(_gps(6, 6));
    estimator.addSample(_steps(6, 1006));
    expect(estimator.totalDistance, closeTo(6, 1e-6));
  });

  test('reset clears distance, calibration and all sensor baselines', () {
    _walk(estimator);
    estimator.addSample(_gps(16, 16, accuracy: 50));
    estimator.addSample(_steps(16, 1016));
    estimator.reset();
    expect(estimator.totalDistance, 0);
    expect(estimator.hasLearnedStepLength, isFalse);
    expect(estimator.stepLength, 0.7);
    estimator.addSample(_steps(0, 5000));
    estimator.addSample(_steps(1, 5002));
    expect(estimator.totalDistance, closeTo(1.4, 1e-6));
  });
}
