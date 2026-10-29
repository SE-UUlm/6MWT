import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/adaptive_gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/calibrated_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_confidence.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/kalman_gps_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/kalman_gps_step_distance_estimator.dart';

final _epoch = DateTime.utc(2026);
final _metresPerDegree = Geolocator.distanceBetween(0, 0, 0, 1);

SensorSample _gps(int second, double metres, {double accuracy = 3}) =>
    SensorSample(
      timestamp: _epoch.add(Duration(seconds: second)),
      sourceId: 'gps',
      type: SampleType.position,
      values: {
        PositionKeys.latitude: 0,
        PositionKeys.longitude: metres / _metresPerDegree,
        PositionKeys.accuracy: accuracy,
      },
    );

SensorSample _steps(int second, double count) => SensorSample(
  timestamp: _epoch.add(Duration(seconds: second)),
  sourceId: 'pedometer',
  type: SampleType.steps,
  values: {StepKeys.cumulativeSteps: count},
);

/// A straight walk at one metre and one step per second.
void _walk(DistanceEstimator estimator, int seconds, {double accuracy = 3}) {
  for (var i = 0; i <= seconds; i++) {
    estimator.addSample(_gps(i, i.toDouble(), accuracy: accuracy));
    estimator.addSample(_steps(i, (1000 + i).toDouble()));
  }
}

void _stepsOnly(DistanceEstimator estimator, int seconds) {
  for (var i = 0; i <= seconds; i++) {
    estimator.addSample(_steps(i, (1000 + i).toDouble()));
  }
}

final _estimators = <String, DistanceEstimator Function()>{
  'Main': () => GpsStepDistanceEstimator(stepSourceId: 'pedometer'),
  'Plain GPS': GpsDistanceEstimator.new,
  'Filtered GPS': () => FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
  'Kalman GPS': KalmanGpsDistanceEstimator.new,
  'Kalman GPS + steps': KalmanGpsStepDistanceEstimator.new,
  'Adaptive GPS + steps': AdaptiveGpsStepDistanceEstimator.new,
  'Calibrated steps': CalibratedStepDistanceEstimator.new,
  'Steps': () => StepDistanceEstimator(stepLength: 0.75),
};

void main() {
  group('ConfidenceHeuristics', () {
    test('GPS quality scales with accuracy and acceptance', () {
      double quality(double accuracy, {int rejected = 0}) =>
          ConfidenceHeuristics.gpsQuality(
            accuracySum: accuracy * 10,
            accepted: 10,
            rejected: rejected,
          );
      expect(quality(2), 1);
      expect(quality(12), closeTo(0.5, 1e-9));
      expect(quality(27), closeTo(1 / 3, 1e-9));
      expect(quality(75), closeTo(0.2, 1e-9));
      expect(quality(2, rejected: 10), closeTo(0.75, 1e-9));
      expect(
        ConfidenceHeuristics.gpsQuality(
          accuracySum: 0,
          accepted: 0,
          rejected: 3,
        ),
        0,
      );
    });

    test('stride quality needs agreeing calibration windows', () {
      expect(
        ConfidenceHeuristics.strideQuality(const []),
        ConfidenceHeuristics.defaultStrideQuality,
      );
      expect(
        ConfidenceHeuristics.strideQuality(const [0.7]),
        ConfidenceHeuristics.learnedStrideQuality,
      );
      expect(
        ConfidenceHeuristics.strideQuality(List.filled(5, 0.7)),
        closeTo(1, 1e-9),
      );
      // Two agreeing windows count for two fifths of full support.
      expect(
        ConfidenceHeuristics.strideQuality(const [0.7, 0.7]),
        closeTo(0.4 + 0.6 * 0.4, 1e-9),
      );
      expect(
        ConfidenceHeuristics.strideQuality(const [0.5, 0.7, 0.9, 0.5, 0.9]),
        ConfidenceHeuristics.learnedStrideQuality,
      );
      expect(
        ConfidenceHeuristics.strideQuality(List.filled(5, 0.7), rejected: 5),
        closeTo(0.5, 1e-9),
      );
    });

    test('combine weights by GPS share and handles no distance', () {
      expect(
        ConfidenceHeuristics.combine(
          total: 0,
          gpsDistance: 0,
          gpsQuality: 1,
          otherQuality: 1,
        ).score,
        0,
      );
      expect(
        ConfidenceHeuristics.combine(
          total: 100,
          gpsDistance: 25,
          gpsQuality: 1,
          otherQuality: 0.2,
        ).score,
        closeTo(0.4, 1e-9),
      );
    });
  });

  group('every comparison estimator reports a confidence', () {
    for (final MapEntry(key: name, value: create) in _estimators.entries) {
      test('$name: none before any distance, cleared by reset', () {
        final estimator = create();
        expect(estimator.confidence?.score, 0);
        _walk(estimator, 120);
        expect(estimator.confidence!.score, greaterThan(0));
        estimator.reset();
        expect(estimator.confidence?.score, 0);
      });
    }

    for (final name in [
      'Main',
      'Plain GPS',
      'Filtered GPS',
      'Kalman GPS',
      'Kalman GPS + steps',
      'Adaptive GPS + steps',
      'Calibrated steps',
    ]) {
      test('$name: high for an accurate, consistent walk', () {
        final estimator = _estimators[name]!();
        _walk(estimator, 120);
        expect(estimator.confidence!.level, ConfidenceLevel.high);
      });
    }

    for (final name in ['Plain GPS', 'Filtered GPS', 'Kalman GPS']) {
      test('$name: poor accuracy lowers the confidence', () {
        final good = _estimators[name]!();
        final poor = _estimators[name]!();
        _walk(good, 120);
        _walk(poor, 120, accuracy: 15);
        expect(poor.confidence!.score, lessThan(good.confidence!.score));
        expect(poor.confidence!.level, isNot(ConfidenceLevel.high));
      });
    }

    for (final name in [
      'Main',
      'Kalman GPS + steps',
      'Adaptive GPS + steps',
      'Calibrated steps',
      'Steps',
    ]) {
      test('$name: low for steps with an uncalibrated stride', () {
        final estimator = _estimators[name]!();
        _stepsOnly(estimator, 120);
        expect(
          estimator.confidence!.score,
          closeTo(ConfidenceHeuristics.defaultStrideQuality, 1e-9),
        );
      });
    }

    test('Plain GPS: implausible jumps lower the confidence', () {
      final estimator = GpsDistanceEstimator();
      for (var i = 0; i <= 60; i++) {
        // Every tenth fix jumps 30 m sideways along the track.
        estimator.addSample(_gps(i, i % 10 == 5 ? i + 30.0 : i.toDouble()));
      }
      expect(estimator.confidence.score, lessThan(0.95));
    });

    test('Kalman GPS: bridged gaps lower the confidence', () {
      final estimator = KalmanGpsDistanceEstimator();
      for (var i = 0; i <= 60; i++) {
        estimator.addSample(_gps(i, i.toDouble()));
      }
      // Sixty metres walked during the outage are bridged in a straight line.
      for (var i = 120; i <= 130; i++) {
        estimator.addSample(_gps(i, i.toDouble()));
      }
      expect(estimator.additionalInfo['GPS gaps'], '1');
      expect(estimator.confidence.score, lessThan(0.9));
    });
  });
}
