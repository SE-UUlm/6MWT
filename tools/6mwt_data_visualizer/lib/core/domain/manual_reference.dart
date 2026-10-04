import 'package:latlong2/latlong.dart';

import 'haversine.dart';
import 'sensor_sample.dart';
import 'session.dart';

/// A hand-drawn route has geometry, but no measured timing. Assign times in
/// proportion to cumulative distance (constant speed) across the active window.
Session createManualReference(
  Session session,
  List<LatLng> points,
  String name,
) {
  if (name.trim().isEmpty) throw ArgumentError('Enter a reference name.');
  if (points.length < 2) throw ArgumentError('Add at least two points.');
  final cumulative = <double>[0];
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    if (!p.latitude.isFinite ||
        !p.longitude.isFinite ||
        p.latitude.abs() > 90 ||
        p.longitude.abs() > 180) {
      throw ArgumentError('Invalid coordinates.');
    }
    if (i > 0) {
      cumulative.add(
        cumulative.last +
            haversineDistance(
              lat1: points[i - 1].latitude,
              lon1: points[i - 1].longitude,
              lat2: p.latitude,
              lon2: p.longitude,
            ),
      );
    }
  }
  final distance = cumulative.last;
  if (distance <= 0) {
    throw ArgumentError('The path must have a positive length.');
  }
  final start = session.sessionStartUtc;
  final window = session.sessionEndUtc.difference(start);
  if (window.inMicroseconds <= 0) {
    throw ArgumentError('The recording must have a positive duration.');
  }
  return Session(
    id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
    notes: name.trim(),
    referenceName: name.trim(),
    isManualReference: true,
    startedAt: start,
    duration: window.inSeconds,
    distance: distance,
    phase: 'completed',
    profileId: session.profileId,
    samples: [
      for (var i = 0; i < points.length; i++)
        SensorSample(
          id: i,
          timestamp: start.add(
            Duration(
              microseconds: (window.inMicroseconds * cumulative[i] / distance)
                  .round(),
            ),
          ),
          type: SampleType.position,
          sourceId: 'manual-reference',
          values: {
            PositionKeys.latitude: points[i].latitude,
            PositionKeys.longitude: points[i].longitude,
            PositionKeys.distance: cumulative[i],
          },
        ),
    ],
  );
}
