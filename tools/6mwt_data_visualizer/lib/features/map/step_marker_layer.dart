import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/domain/haversine.dart';
import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';

/// Uses screen-space label bounds rather than sample count or fixed zoom steps.
/// All visible recordings share one collision grid, including crossing tracks.
/// Deltas always refer to the preceding raw GPS sample, not the previous label.
class StepMarkerLayer extends StatefulWidget {
  const StepMarkerLayer({super.key, required this.sessions});

  final List<Session> sessions;

  @override
  State<StepMarkerLayer> createState() => _StepMarkerLayerState();
}

class _StepMarkerLayerState extends State<StepMarkerLayer> {
  final _data = <Session, List<_SegmentData>>{};

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(StepMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prepare();
  }

  void _prepare() {
    _data.removeWhere((session, _) => !widget.sessions.contains(session));
    for (final session in widget.sessions) {
      _data.putIfAbsent(session, () => _segments(session));
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(9) / 9;
    final labelSize = Size(64 * scale, 36 * scale);
    final placement = ScreenLabelPlacement(
      viewport: Offset.zero & camera.nonRotatedSize,
      labelSize: labelSize,
    );
    final markers = <Marker>[];
    final iterators = [for (final s in widget.sessions) _data[s]!.iterator];

    // Give each recording a turn instead of filling the map with the first one.
    var hasMore = true;
    while (hasMore) {
      hasMore = false;
      for (var i = 0; i < iterators.length; i++) {
        final iterator = iterators[i];
        if (!iterator.moveNext()) continue;
        hasMore = true;
        final data = iterator.current;
        final offset = camera.latLngToScreenOffset(data.point);
        if (data.gpsDelta == null) {
          if (data.accuracy != null && placement.viewport.contains(offset)) {
            markers.add(
              Marker(
                point: data.point,
                width: 20,
                height: 20,
                child: Tooltip(
                  message: 'Accuracy: ${data.accuracy!.toStringAsFixed(1)} m',
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
            );
          }
          continue;
        }
        if (!placement.add(offset)) continue;
        markers.add(
          Marker(
            point: data.point,
            width: labelSize.width,
            height: labelSize.height,
            alignment: Alignment.topCenter,
            rotate: true,
            child: _SegmentLabel(
              gpsDelta: data.gpsDelta!,
              stepDelta: data.stepDelta,
              accuracy: data.accuracy,
              recording: widget.sessions.length > 1
                  ? widget.sessions[i].deviceLabel
                  : null,
            ),
          ),
        );
      }
    }
    return MarkerLayer(markers: markers);
  }
}

/// Greedy screen-space placement with a spatial grid: bounded neighbour checks
/// instead of comparing every sample to every already accepted label.
class ScreenLabelPlacement {
  ScreenLabelPlacement({
    required Rect viewport,
    required this.labelSize,
    this.gap = 4,
  }) : viewport = viewport.deflate(4);

  final Rect viewport;
  final Size labelSize;
  final double gap;
  final _cells = <(int, int), List<Rect>>{};

  bool add(Offset anchor) {
    if (!anchor.dx.isFinite || !anchor.dy.isFinite) return false;
    final bounds = Rect.fromLTWH(
      anchor.dx - labelSize.width / 2,
      anchor.dy - labelSize.height,
      labelSize.width,
      labelSize.height,
    );
    if (bounds.left < viewport.left ||
        bounds.right > viewport.right ||
        bounds.top < viewport.top ||
        bounds.bottom > viewport.bottom) {
      return false;
    }
    final padded = bounds.inflate(gap / 2);
    final width = labelSize.width + gap, height = labelSize.height + gap;
    final left = (padded.left / width).floor(),
        right = (padded.right / width).floor();
    final top = (padded.top / height).floor(),
        bottom = (padded.bottom / height).floor();
    for (var x = left; x <= right; x++) {
      for (var y = top; y <= bottom; y++) {
        if ((_cells[(x, y)] ?? const <Rect>[]).any((r) => r.overlaps(padded))) {
          return false;
        }
      }
    }
    for (var x = left; x <= right; x++) {
      for (var y = top; y <= bottom; y++) {
        _cells.putIfAbsent((x, y), () => []).add(padded);
      }
    }
    return true;
  }
}

class _SegmentData {
  const _SegmentData(this.point, this.gpsDelta, this.stepDelta, this.accuracy);
  final LatLng point;
  final double? gpsDelta;
  final int? stepDelta;
  final double? accuracy;
}

/// Prepare once per recording. Merge chronological GPS/step streams in O(n+m)
/// so camera movement never repeats distance calculations or history scans.
List<_SegmentData> _segments(Session session) {
  final positions = session.positionSamples, steps = session.stepSamples;
  final result = <_SegmentData>[];
  SensorSample? previous;
  double? previousSteps, cumulativeSteps;
  var stepIndex = 0;
  for (final sample in positions) {
    while (stepIndex < steps.length &&
        !steps[stepIndex].timestamp.isAfter(sample.timestamp)) {
      cumulativeSteps = steps[stepIndex++].values[StepKeys.cumulativeSteps];
    }
    final lat = sample.values[PositionKeys.latitude]!,
        lon = sample.values[PositionKeys.longitude]!;
    result.add(
      _SegmentData(
        LatLng(lat, lon),
        previous == null
            ? null
            : haversineDistance(
                lat1: previous.values[PositionKeys.latitude]!,
                lon1: previous.values[PositionKeys.longitude]!,
                lat2: lat,
                lon2: lon,
              ),
        cumulativeSteps == null || previousSteps == null
            ? null
            : (cumulativeSteps - previousSteps).round(),
        sample.values[PositionKeys.accuracy],
      ),
    );
    previous = sample;
    if (cumulativeSteps != null) previousSteps = cumulativeSteps;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Label widget
// ---------------------------------------------------------------------------

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.gpsDelta,
    this.stepDelta,
    this.accuracy,
    this.recording,
  });

  final double gpsDelta;
  final int? stepDelta;
  final double? accuracy;
  final String? recording;

  @override
  Widget build(BuildContext context) {
    final gpsText = '+${gpsDelta.toStringAsFixed(1)} m';
    final stepsText = stepDelta != null ? '+$stepDelta steps' : null;
    final accuracyText = accuracy != null
        ? 'Accuracy: ${accuracy!.toStringAsFixed(1)} m'
        : null;

    return Tooltip(
      message:
          '${recording == null ? '' : '$recording\n'}'
          'GPS segment: $gpsText'
          '${stepsText != null ? '\n$stepsText' : ''}'
          '${accuracyText != null ? '\n$accuracyText' : ''}',
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
