import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';

import '../domain/estimator_comparison.dart';

/// In-memory results of the just-completed walk, independent of session reset.
class WalkResultArguments {
  WalkResultArguments({
    required this.session,
    required List<EstimatorComparison> comparisons,
  }) : comparisons = List.unmodifiable(comparisons);

  final WalkSessionWithProfile session;
  final List<EstimatorComparison> comparisons;
}
