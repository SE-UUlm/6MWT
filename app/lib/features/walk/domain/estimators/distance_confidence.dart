import 'dart:math' as math;

enum ConfidenceLevel { low, medium, high }

/// Heuristic trust in an estimated distance, from 0 (none) to 1 (high).
/// It summarises input quality; it is not a calibrated error bound.
class DistanceConfidence {
  const DistanceConfidence(this.score)
    : assert(score >= 0 && score <= 1, 'Score must be within 0..1');

  static const highThreshold = 0.75;
  static const mediumThreshold = 0.5;

  final double score;

  ConfidenceLevel get level => score >= highThreshold
      ? ConfidenceLevel.high
      : score >= mediumThreshold
      ? ConfidenceLevel.medium
      : ConfidenceLevel.low;

  int get percent => (score * 100).round();

  @override
  String toString() => '${level.name} ($percent %)';
}

/// Shared scoring so that estimator confidences remain comparable. Every
/// estimator uses the same accuracy scale, whatever its own acceptance limit.
abstract final class ConfidenceHeuristics {
  // Mean accuracy at or below goodGpsAccuracy counts as fully trustworthy;
  // beyond it, trust falls with the inverse square root, without a floor
  // (6 m ≈ 0.71, 10 m ≈ 0.55, 30 m ≈ 0.32).
  // Stride variation at maxStrideVariation counts as inconsistent; consistency
  // counts fully with fullStrideSupport calibration windows.
  static const goodGpsAccuracy = 3.0;
  static const missingGpsAccuracy = 10.0;
  static const maxStrideVariation = 0.2;
  static const fullStrideSupport = 5;
  static const defaultStrideQuality = 0.3;
  static const learnedStrideQuality = 0.4;

  /// Straight-line bridges over GPS gaps carry no route information.
  static const gapBridgeQuality = 0.3;

  /// Accurate fixes and few rejected readings indicate a usable GPS track.
  /// Missing accuracies should be passed as [missingGpsAccuracy].
  static double gpsQuality({
    required double accuracySum,
    required int accepted,
    required int rejected,
  }) {
    if (accepted <= 0) return 0;
    final meanAccuracy = accuracySum / accepted;
    final accuracy = math.sqrt(
      goodGpsAccuracy / math.max(meanAccuracy, goodGpsAccuracy),
    );
    final acceptance = accepted / (accepted + rejected);
    return accuracy * (0.5 + 0.5 * acceptance);
  }

  /// Agreeing calibration windows indicate a reliable stride. Without any,
  /// the stride is an assumed default.
  static double strideQuality(List<double> strides, {int rejected = 0}) {
    final count = strides.length;
    if (count == 0) return defaultStrideQuality;
    final acceptance = count / (count + rejected);
    if (count == 1) return learnedStrideQuality * acceptance;
    final mean = strides.reduce((a, b) => a + b) / count;
    final variance =
        strides.fold(0.0, (v, c) => v + (c - mean) * (c - mean)) / (count - 1);
    final variation = math.sqrt(variance) / mean;
    final consistency = 1 - (variation / maxStrideVariation).clamp(0.0, 1.0);
    final support = math.min(1.0, count / fullStrideSupport);
    return (learnedStrideQuality +
            (1 - learnedStrideQuality) * consistency * support) *
        acceptance;
  }

  /// Weights two qualities by their share of [total]; no distance, no trust.
  static DistanceConfidence combine({
    required double total,
    required double gpsDistance,
    required double gpsQuality,
    required double otherQuality,
  }) {
    if (total <= 0) return const DistanceConfidence(0);
    final gpsShare = (gpsDistance / total).clamp(0.0, 1.0);
    return DistanceConfidence(
      (gpsShare * gpsQuality + (1 - gpsShare) * otherQuality).clamp(0.0, 1.0),
    );
  }
}
