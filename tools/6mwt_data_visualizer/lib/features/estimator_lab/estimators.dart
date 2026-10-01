import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';

import 'experimental_estimators.dart';

/// Edit this list to choose algorithms and parameters shown in the tool.
/// Each session gets new instances; multiple configurations of a class are allowed.
List<DistanceEstimator> createEstimators() => [
  GpsDistanceEstimator(),
  FilteredGpsEstimator(maxAccuracy: 20, maxSpeed: 3),
  StepDistanceEstimator(stepLength: 0.75),
];
