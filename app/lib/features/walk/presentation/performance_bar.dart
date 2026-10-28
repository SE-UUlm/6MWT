import 'package:flutter/material.dart';

import '../domain/fitness_assessment.dart';

/// Colors of the performance scale, from low to high performance.
const performanceScaleColors = <FitnessCategory, Color>{
  FitnessCategory.reducedPhysicalPerformance: Color(0xFFf94144),
  FitnessCategory.lowNormal: Color(0xFFf8961e),
  FitnessCategory.normalPopulationMean: Color(0xFF90be6d),
  FitnessCategory.highNormal: Color(0xFF43aa8b),
  FitnessCategory.topPerformance: Color(0xFF577590),
};

/// Colored scale of the percentage of the expected walking distance.
///
/// The category boundaries depend on the [expectedDistance], because they are
/// a fixed distance in metres away from it. Without a [percentage], only the
/// scale is shown, without a marker.
class PerformanceBar extends StatelessWidget {
  const PerformanceBar({
    super.key,
    required this.expectedDistance,
    this.percentage,
  });

  final double expectedDistance;
  final double? percentage;

  // All category boundaries lie within this range for the supported ages and
  // heights, so the scale skips the irrelevant part below it.
  static const minValue = 60.0;
  static const maxValue = 140.0;
  static const labels = [60, 80, 100, 120, 140];

  // Half the width of the color transition around each category boundary, in
  // percentage points. The narrowest category is still wider than a full
  // transition, so every category keeps an area of constant color.
  static const transitionHalfWidth = 1.5;

  static double _position(double value) =>
      ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = performanceScaleColors.values.toList();
    final boundaries = categoryBoundariesInPercent(expectedDistance);

    // Each category color is constant up to shortly before the next boundary
    // and then blends into the next color.
    final gradientColors = [colors.first];
    final stops = [0.0];
    for (final (index, boundary) in boundaries.indexed) {
      gradientColors
        ..add(colors[index])
        ..add(colors[index + 1]);
      stops
        ..add(_position(boundary - transitionHalfWidth))
        ..add(_position(boundary + transitionHalfWidth));
    }
    gradientColors.add(colors.last);
    stops.add(1.0);

    final progress = percentage?.clamp(minValue, maxValue);

    // The layout builders sit inside fixed heights, as a LayoutBuilder cannot
    // report an intrinsic height (needed e.g. in a SliverFillRemaining).
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: gradientColors,
                        stops: stops,
                      ),
                    ),
                  ),
                ),

                if (progress != null)
                  Positioned(
                    key: const ValueKey('performance-marker'),
                    left: constraints.maxWidth * _position(progress) - 2,
                    top: -6,
                    child: Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Each label is centered below its value on the scale.
        SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              clipBehavior: Clip.none,
              children: [
                for (final label in labels)
                  Positioned(
                    left: constraints.maxWidth * _position(label.toDouble()),
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(
                        '$label %',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
