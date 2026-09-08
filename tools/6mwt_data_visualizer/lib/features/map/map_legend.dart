import 'package:flutter/material.dart';

import '../../core/domain/session.dart';
import '../../core/theme/app_colors.dart';

/// Compact legend overlay showing track distances and reference comparison.
class MapLegend extends StatelessWidget {
  const MapLegend({
    super.key,
    required this.session,
    required this.refSession,
    required this.appPointsCount,
    required this.refPointsCount,
    required this.isTrimmed,
  });

  final Session session;
  final Session? refSession;
  final int appPointsCount;
  final int refPointsCount;
  final bool isTrimmed;

  @override
  Widget build(BuildContext context) {
    final deltaDist = refSession != null
        ? session.distance - refSession!.distance
        : 0.0;
    final deltaPct = refSession != null && refSession!.distance > 0
        ? ((session.distance - refSession!.distance) /
                refSession!.distance) *
            100
        : 0.0;

    return Card(
      elevation: 4,
      color: Colors.black.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.appTrackBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '📱 6MWT App: ${session.distance.toStringAsFixed(1)} m '
                  '($appPointsCount GPS)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (refSession != null) ...[
              const SizedBox(height: 5),
              // Reference row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.referenceOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🎯 Reference${isTrimmed ? ' (trimmed)' : ' (full)'}: '
                    '${refSession!.distance.toStringAsFixed(1)} m '
                    '($refPointsCount GPS)',
                    style: const TextStyle(
                      color: AppColors.referenceTextOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Delta row
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  'Δ Distance: ${deltaDist >= 0 ? '+' : ''}'
                  '${deltaDist.toStringAsFixed(1)} m '
                  '(${deltaPct >= 0 ? '+' : ''}'
                  '${deltaPct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: deltaDist.abs() <= 15
                        ? Colors.lightGreenAccent
                        : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Esri attribution text (required by Esri Terms of Service).
class EsriAttribution extends StatelessWidget {
  const EsriAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Powered by Esri',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
