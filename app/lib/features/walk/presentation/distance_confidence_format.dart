import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/estimators/distance_confidence.dart';

String formatConfidence(AppLocalizations l10n, DistanceConfidence? confidence) {
  if (confidence == null) return '—';
  final label = switch (confidence.level) {
    ConfidenceLevel.high => l10n.confidenceHigh,
    ConfidenceLevel.medium => l10n.confidenceMedium,
    ConfidenceLevel.low => l10n.confidenceLow,
  };
  return '$label (${l10n.percentValue(confidence.percent)})';
}

Color confidenceColor(DistanceConfidence? confidence) =>
    switch (confidence?.level) {
      ConfidenceLevel.high => const Color(0xFF43aa8b),
      ConfidenceLevel.medium => const Color(0xFFf8961e),
      ConfidenceLevel.low => const Color(0xFFf94144),
      null => Colors.black,
    };
