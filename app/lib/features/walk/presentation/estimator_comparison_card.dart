import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/estimator_comparison.dart';
import 'distance_confidence_format.dart';
import 'number_format.dart';

class EstimatorComparisonCard extends StatelessWidget {
  const EstimatorComparisonCard({super.key, required this.comparisons});

  final List<EstimatorComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.resultDistanceComparison,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          for (final result in comparisons) ...[
            const SizedBox(height: 12),
            Text(
              _estimatorLabel(l10n, result),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              result.error == null
                  ? '${formatDecimal(l10n, result.distance, 1)} m'
                  : l10n.comparisonUnavailable(result.error!),
            ),
            if (result.error == null && result.confidence != null)
              Text(
                l10n.comparisonConfidence(
                  formatConfidence(l10n, result.confidence),
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: confidenceColor(result.confidence),
                ),
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

// Estimator names are technical terms and stay untranslated.
String _estimatorLabel(AppLocalizations l10n, EstimatorComparison result) =>
    result.isPrimary ? l10n.estimatorMain(result.name) : result.name;
