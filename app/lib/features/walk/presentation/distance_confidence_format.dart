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

// Dark enough to be readable as text on white (WCAG AA).
Color confidenceColor(DistanceConfidence? confidence) =>
    switch (confidence?.level) {
      ConfidenceLevel.high => const Color(0xFF008566),
      ConfidenceLevel.medium => const Color(0xFFBF5900),
      ConfidenceLevel.low => const Color(0xFFDD0000),
      null => Colors.black,
    };
