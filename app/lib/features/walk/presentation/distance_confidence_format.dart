import 'package:flutter/material.dart';

import '../domain/estimators/distance_confidence.dart';

String formatConfidence(DistanceConfidence? confidence) {
  if (confidence == null) return '-';
  final label = switch (confidence.level) {
    ConfidenceLevel.high => 'High',
    ConfidenceLevel.medium => 'Medium',
    ConfidenceLevel.low => 'Low',
  };
  return '$label (${confidence.percent} %)';
}

Color confidenceColor(DistanceConfidence? confidence) =>
    switch (confidence?.level) {
      ConfidenceLevel.high => const Color(0xFF43aa8b),
      ConfidenceLevel.medium => const Color(0xFFf8961e),
      ConfidenceLevel.low => const Color(0xFFf94144),
      null => Colors.black,
    };
