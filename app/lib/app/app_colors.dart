import 'package:flutter/material.dart';

/// Colors shared across screens. Screen-specific colors stay in their screen.
abstract final class AppColors {
  /// Buttons, links and accents. Dark enough for white text on it and for
  /// blue text on white (WCAG AA, 4.58:1).
  static const primaryBlue = Color(0xFF2E72DF);

  /// Light blue background of the walking icon in the title bar and of the
  /// progress circle.
  static const circleBlue = Color(0xFF9BB8F0);
}
