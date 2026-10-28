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
/// Without a [percentage], only the scale is shown, without a marker.
class PerformanceBar extends StatelessWidget {
  const PerformanceBar({super.key, this.percentage});

  final double? percentage;

  static const maxValue = 140;
  static const labelCount = 7;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress = percentage?.clamp(0, maxValue);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: performanceScaleColors.values.toList(),
                          stops: const [
                            0.0 / maxValue,
                            80 / maxValue,
                            90 / maxValue,
                            110 / maxValue,
                            120 / maxValue,
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (progress != null)
                    Positioned(
                      key: const ValueKey('performance-marker'),
                      left: constraints.maxWidth * progress / maxValue - 2,
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
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            for (int i = 0; i < labelCount; i++)
              Expanded(
                child: Text(
                  '${(maxValue / labelCount * (i + 0.5)).toStringAsFixed(0)} %',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
