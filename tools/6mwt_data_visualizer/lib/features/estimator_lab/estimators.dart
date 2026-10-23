import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/kalman_gps_step_distance_estimator.dart';

import 'package:six_minute_walk_test/features/walk/domain/estimators/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/kalman_gps_distance_estimator.dart';

import 'package:six_minute_walk_test/features/walk/domain/estimators/calibrated_step_distance_estimator.dart';

import 'package:six_minute_walk_test/features/walk/domain/estimators/adaptive_gps_step_distance_estimator.dart';

/// Edit this list to choose algorithms and parameters shown in the tool.
/// Each session gets new instances; multiple configurations of a class are allowed.
List<DistanceEstimator> createEstimators() => [
  GpsDistanceEstimator(),
  FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
  KalmanGpsDistanceEstimator(),
  StepDistanceEstimator(stepLength: 0.75),
  for (final seconds in [5, 10, 15])
    GpsStepDistanceEstimator(
      name: 'GPS + steps (GPS ≤ $seconds s)',
      stepSourceId: PedometerSource.id,
      maxGpsInterval: Duration(seconds: seconds),
    ),
  CalibratedStepDistanceEstimator(),
  AdaptiveGpsStepDistanceEstimator(),
  KalmanGpsStepDistanceEstimator(),
];
