import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/gps_step_distance_estimator.dart';

import 'package:six_minute_walk_test/features/walk/domain/experimental_estimators.dart';
import 'package:six_minute_walk_test/features/walk/domain/kalman_gps_distance_estimator.dart';

import 'package:six_minute_walk_test/features/walk/domain/calibrated_step_distance_estimator.dart';

/// Edit this list to choose algorithms and parameters shown in the tool.
/// Each session gets new instances; multiple configurations of a class are allowed.
List<DistanceEstimator> createEstimators() => [
  GpsDistanceEstimator(),
  CalibratedStepDistanceEstimator(),
  FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
  KalmanGpsDistanceEstimator(),
  StepDistanceEstimator(stepLength: 0.75),
  for (final seconds in [5, 10, 15])
    GpsStepDistanceEstimator(
      stepSourceId: PedometerSource.id,
      maxGpsInterval: Duration(seconds: seconds),
    ),
];
