import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';

class GpsTrackLayer extends StatelessWidget {
  const GpsTrackLayer({
    super.key,
    required this.session,
    required this.gpsPoints,
    this.trackColor = const Color(0xFF42A5F5), // Blue shade 400
    this.startColor = Colors.green,
    this.endColor = Colors.red,
    this.startLabel = 'Start',
    this.endLabel = 'End',
    this.showAccuracyCircles = true,
    this.isReference = false,
  });

  final Session session;
  final List<LatLng> gpsPoints;
  final Color trackColor;
  final Color startColor;
  final Color endColor;
  final String startLabel;
  final String endLabel;
  final bool showAccuracyCircles;
  final bool isReference;

  @override
  Widget build(BuildContext context) {
    if (gpsPoints.isEmpty) return const SizedBox.shrink();

    final zoom = MapCamera.of(context).zoom;

    // Filter accuracy circles to points that actually have accuracy > 0
    final accuracyCircles = showAccuracyCircles
        ? session.positionSamples
            .where((s) => (s.values[PositionKeys.accuracy] ?? 0) > 0)
            .map((s) {
            final lat = s.values[PositionKeys.latitude]!;
            final lon = s.values[PositionKeys.longitude]!;
            final accuracy = s.values[PositionKeys.accuracy]!;
            return CircleMarker(
              point: LatLng(lat, lon),
              radius: accuracy,
              useRadiusInMeter: true,
              color: trackColor.withValues(alpha: 0.06),
              borderColor: trackColor.withValues(alpha: 0.20),
              borderStrokeWidth: 0.5,
            );
          }).toList()
        : const <CircleMarker>[];

    return Stack(
      children: [
        // Accuracy circles for each GPS point
        if (accuracyCircles.isNotEmpty)
          CircleLayer(circles: accuracyCircles),

        // GPS track polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: gpsPoints,
              strokeWidth: isReference ? 3.0 : 3.5,
              color: trackColor,
              pattern: isReference
                  ? StrokePattern.dashed(segments: const [8, 4])
                  : const StrokePattern.solid(),
            ),
          ],
        ),

        // Small dots at each GPS position – shown at zoom ≥ 18
        if (zoom >= 18)
          CircleLayer(
            circles: gpsPoints
                .map(
                  (p) => CircleMarker(
                    point: p,
                    radius: isReference ? 3.5 : 4,
                    color: Colors.white,
                    borderColor: trackColor,
                    borderStrokeWidth: 1.5,
                  ),
                )
                .toList(),
          ),

        // Start / end markers
        MarkerLayer(
          markers: [
            _buildMarker(
              gpsPoints.first,
              isReference ? Icons.flag_rounded : Icons.play_arrow_rounded,
              startColor,
              label: startLabel,
              isSquare: isReference,
            ),
            _buildMarker(
              gpsPoints.last,
              isReference ? Icons.sports_score_rounded : Icons.stop_rounded,
              endColor,
              label: endLabel,
              isSquare: isReference,
            ),
          ],
        ),
      ],
    );
  }

  Marker _buildMarker(
    LatLng point,
    IconData icon,
    Color color, {
    required String label,
    bool isSquare = false,
  }) {
    return Marker(
      point: point,
      width: 68,
      height: 46,
      alignment: Alignment.topCenter,
      child: Tooltip(
        message: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: color,
                shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isSquare ? BorderRadius.circular(6) : null,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color, width: 0.8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
