import 'estimators/distance_confidence.dart';
import 'estimators/distance_estimator.dart';

/// A frozen result, safe to retain after the session has been reset.
class EstimatorComparison {
  EstimatorComparison({
    required this.name,
    required this.distance,
    Map<String, String> additionalInfo = const {},
    this.confidence,
    this.error,
  }) : additionalInfo = Map.unmodifiable(additionalInfo);

  /// Snapshots [estimator]'s current result; [primary] marks the estimator
  /// that drives the session distance. Throws on an invalid distance.
  factory EstimatorComparison.of(
    DistanceEstimator estimator, {
    bool primary = false,
  }) {
    final distance = estimator.totalDistance;
    if (!distance.isFinite || distance < 0) {
      throw StateError('Invalid calculated distance: $distance');
    }
    return EstimatorComparison(
      name: displayName(estimator, primary: primary),
      distance: distance,
      additionalInfo: estimator.additionalInfo,
      confidence: estimator.confidence,
    );
  }

  /// A result for an estimator that could not provide a distance.
  EstimatorComparison.failed(
    DistanceEstimator estimator,
    Object error, {
    bool primary = false,
  }) : this(
         name: displayName(estimator, primary: primary),
         distance: 0,
         error: error.toString(),
       );

  static String displayName(
    DistanceEstimator estimator, {
    bool primary = false,
  }) => primary ? 'Main (${estimator.name})' : estimator.name;

  final String name;
  final double distance;
  final Map<String, String> additionalInfo;
  final DistanceConfidence? confidence;
  final String? error;
}
