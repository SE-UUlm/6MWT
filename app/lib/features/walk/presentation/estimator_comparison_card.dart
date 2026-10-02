import 'package:flutter/material.dart';

import '../domain/estimator_comparison.dart';

class EstimatorComparisonCard extends StatelessWidget {
  const EstimatorComparisonCard({super.key, required this.comparisons});

  final List<EstimatorComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    if (comparisons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Distance comparison',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          for (final result in comparisons) ...[
            const SizedBox(height: 12),
            Text(
              result.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              result.error == null
                  ? '${result.distance.toStringAsFixed(1)} m'
                  : 'Estimator unavailable: ${result.error}',
            ),
            if (result.error == null)
              for (final info in result.additionalInfo.entries)
                Text(
                  '${info.key}: ${info.value}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
          ],
        ],
      ),
    );
  }
}
