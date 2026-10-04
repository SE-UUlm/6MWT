import 'distance_estimator.dart';

/// A separately owned estimator instance and its display name.
class NamedDistanceEstimator {
  const NamedDistanceEstimator(this.name, this.estimator);

  final String name;
  final DistanceEstimator estimator;
}

/// A frozen result, safe to retain after the session has been reset.
class EstimatorComparison {
  EstimatorComparison({
    required this.name,
    required this.distance,
    Map<String, String> additionalInfo = const {},
    this.error,
  }) : additionalInfo = Map.unmodifiable(additionalInfo);

  final String name;
  final double distance;
  final Map<String, String> additionalInfo;
  final String? error;
}
