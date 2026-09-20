import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/domain/haversine.dart';
import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';

/// Shows per-segment labels on the map at each (shown) GPS position.
///
/// Each label displays:
///   +X.X m    – GPS distance from the previous GPS sample (Haversine)
///   +Y steps  – cumulative-step delta since the previous GPS sample
///
/// The marker density adapts automatically to the current zoom level:
///   zoom ≥ 19  → every point
///   zoom ≥ 18  → every 2nd point
///   zoom ≥ 17  → every 3rd point
///   zoom ≥ 16  → every 5th point
///   zoom < 16  → every 10th point
class StepMarkerLayer extends StatelessWidget {
  const StepMarkerLayer({
    super.key,
    required this.session,
    required this.gpsPoints,
  });

  final Session session;
  final List<LatLng> gpsPoints;

  int _strideForZoom(double zoom) {
    if (zoom >= 19) return 1;
    if (zoom >= 18) return 2;
    if (zoom >= 17) return 3;
    if (zoom >= 16) return 5;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    final positionSamples = session.positionSamples;
    if (positionSamples.isEmpty) return const SizedBox.shrink();

    final stepSamples = session.stepSamples;

    final zoom = MapCamera.of(context).zoom;
    final stride = _strideForZoom(zoom);

    final markers = <Marker>[];

    // Previous values for delta computation – always track across ALL samples,
    // but only emit a marker every [stride] samples.
    double? prevLat;
    double? prevLon;
    double? prevSteps;

    for (int i = 0; i < positionSamples.length; i++) {
      final sample = positionSamples[i];
      final lat = sample.values[PositionKeys.latitude]!;
      final lon = sample.values[PositionKeys.longitude]!;

      // GPS distance delta to the immediately preceding GPS sample.
      final double? gpsDelta = (prevLat != null && prevLon != null)
          ? haversineDistance(
              lat1: prevLat,
              lon1: prevLon,
              lat2: lat,
              lon2: lon,
            )
          : null;

      // Step delta to the immediately preceding GPS sample timestamp.
      final cumSteps = stepSamples.isNotEmpty
          ? _stepsAtTime(stepSamples, sample.timestamp)
          : null;
      final int? stepDelta = (cumSteps != null && prevSteps != null)
          ? (cumSteps - prevSteps).round()
          : null;

      prevLat = lat;
      prevLon = lon;
      if (cumSteps != null) prevSteps = cumSteps;

      // Only emit a marker every [stride] samples.
      if (i % stride != 0) continue;
      // No label on the very first point (no delta yet).
      if (gpsDelta == null) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lon),
          width: 64,
          height: 36,
          alignment: Alignment.topCenter,
          child: _SegmentLabel(
            gpsDelta: gpsDelta,
            stepDelta: stepDelta,
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  double? _stepsAtTime(List<SensorSample> stepSamples, DateTime time) {
    SensorSample? nearest;
    for (final s in stepSamples) {
      if (!s.timestamp.isAfter(time)) {
        nearest = s;
      } else {
        break;
      }
    }
    return nearest?.values[StepKeys.cumulativeSteps];
  }
}

// ---------------------------------------------------------------------------
// Label widget
// ---------------------------------------------------------------------------

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.gpsDelta, this.stepDelta});

  final double gpsDelta;
  final int? stepDelta;

  @override
  Widget build(BuildContext context) {
    final gpsText = '+${gpsDelta.toStringAsFixed(1)} m';
    final stepsText = stepDelta != null ? '+$stepDelta steps' : null;

    return Tooltip(
      message: 'GPS segment: $gpsText'
          '${stepsText != null ? '\n$stepsText' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gpsText,
              style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            if (stepsText != null)
              Text(
                stepsText,
                style: TextStyle(
                  color: Colors.blue.shade200,
                  fontSize: 8,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
