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
  });

  final Session session;
  final List<LatLng> gpsPoints;

  @override
  Widget build(BuildContext context) {
    if (gpsPoints.isEmpty) return const SizedBox.shrink();

    final zoom = MapCamera.of(context).zoom;

    return Stack(
      children: [
        // GPS track polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: gpsPoints,
              strokeWidth: 3.5,
              color: Colors.blue.shade300,
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
                    radius: 4,
                    color: Colors.white,
                    borderColor: Colors.blue.shade400,
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
              Icons.play_arrow_rounded,
              Colors.green,
              label: 'Start',
            ),
            _buildMarker(
              gpsPoints.last,
              Icons.stop_rounded,
              Colors.red,
              label: 'Ende',
            ),
          ],
        ),
        // Accuracy circles for each GPS point
        CircleLayer(
          circles: session.positionSamples.map((s) {
            final lat = s.values[PositionKeys.latitude]!;
            final lon = s.values[PositionKeys.longitude]!;
            final accuracy = s.values[PositionKeys.accuracy] ?? 0;
            return CircleMarker(
              point: LatLng(lat, lon),
              radius: accuracy,
              useRadiusInMeter: true,
              color: Colors.blue.withValues(alpha: 0.05),
              borderColor: Colors.blue.withValues(alpha: 0.15),
              borderStrokeWidth: 0.5,
            );
          }).toList(),
        ),
      ],
    );
  }

  Marker _buildMarker(
    LatLng point,
    IconData icon,
    Color color, {
    required String label,
  }) {
    return Marker(
      point: point,
      width: 36,
      height: 36,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
