import 'package:flutter/material.dart';

import '../../core/domain/session.dart';
import '../../core/theme/reference_colors.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({
    super.key,
    required this.session,
    required this.references,
    required this.appPointsCount,
    required this.isTrimmed,
  });
  final Session session;
  final List<Session> references;
  final int appPointsCount;
  final bool isTrimmed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340, maxHeight: 150),
    child: Card(
      color: Colors.black.withValues(alpha: 0.75),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App: ${session.distance.toStringAsFixed(1)} m ($appPointsCount GPS)',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            for (var i = 0; i < references.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${session.referenceLabel(i)}: ${references[i].distance.toStringAsFixed(1)} m'
                  ' (${isTrimmed ? "trimmed" : "full"})'
                  '\nΔ ${(session.distance - references[i].distance).toStringAsFixed(1)} m'
                  '${references[i].distance > 0 ? " (${((session.distance - references[i].distance) / references[i].distance * 100).toStringAsFixed(1)}%)" : ""}'
                  '${references[i].isManualReference ? " · drawn path" : ""}',
                  style: TextStyle(color: referenceColor(i), fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    ),
  );
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
