import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';
import '../../core/theme/app_colors.dart';
import 'gps_track_layer.dart';
import 'map_controls.dart';
import 'map_legend.dart';
import 'step_marker_layer.dart';

class SessionMap extends StatefulWidget {
  const SessionMap({super.key, required this.session});

  final Session session;

  @override
  State<SessionMap> createState() => _SessionMapState();
}

class _SessionMapState extends State<SessionMap> {
  final _mapController = MapController();
  bool _showAppTrack = true;
  bool _showRefTrack = true;
  bool _showStepMarkers = true;
  bool _showAccuracyCircles = true;
  bool _trimReference = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SessionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      _fitBounds();
    }
  }

  Session? get _effectiveReference {
    if (!widget.session.hasReference) return null;
    return _trimReference
        ? (widget.session.trimmedReferenceSession ??
            widget.session.referenceSession)
        : widget.session.referenceSession;
  }

  List<LatLng> _allPoints() {
    final points = <LatLng>[];
    points.addAll(_gpsPoints(widget.session));
    final ref = _effectiveReference;
    if (ref != null) {
      points.addAll(_gpsPoints(ref));
    }
    return points;
  }

  void _fitBounds() {
    final points = _allPoints();
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  List<LatLng> _gpsPoints(Session session) {
    return session.positionSamples.map((s) {
      final lat = s.values[PositionKeys.latitude]!;
      final lon = s.values[PositionKeys.longitude]!;
      return LatLng(lat, lon);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appPoints = _gpsPoints(widget.session);
    final refSession = _effectiveReference;
    final refPoints =
        refSession != null ? _gpsPoints(refSession) : const <LatLng>[];

    final allPoints = _allPoints();
    if (allPoints.isEmpty) {
      return const Center(child: Text('No GPS data for this session.'));
    }

    final bounds = LatLngBounds.fromPoints(allPoints);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(60),
            ),
          ),
          children: [
            // Esri World Imagery (free, no API key required)
            TileLayer(
              urlTemplate:
                  'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'de.uni_ulm.six_mwt_visualizer',
              tileBuilder: _darkModeTileBuilder,
            ),
            // Reference track (drawn below app track)
            if (_showRefTrack && refSession != null && refPoints.isNotEmpty)
              GpsTrackLayer(
                session: refSession,
                gpsPoints: refPoints,
                trackColor: AppColors.referenceOrange,
                startColor: AppColors.referenceStartOrange,
                endColor: AppColors.referenceEndRed,
                startLabel: 'Reference Start',
                endLabel: 'Reference End',
                isReference: true,
                showAccuracyCircles: false,
              ),
            // 6MWT App GPS track
            if (_showAppTrack && appPoints.isNotEmpty)
              GpsTrackLayer(
                session: widget.session,
                gpsPoints: appPoints,
                trackColor: AppColors.appTrackBlue,
                startColor: Colors.green,
                endColor: Colors.red,
                startLabel: 'App Start',
                endLabel: 'App End',
                isReference: false,
                showAccuracyCircles: _showAccuracyCircles,
              ),
            // Step markers (toggleable)
            if (_showStepMarkers && _showAppTrack && appPoints.isNotEmpty)
              StepMarkerLayer(
                  session: widget.session, gpsPoints: appPoints),
            // Esri attribution
            const EsriAttribution(),
          ],
        ),

        // Map Legend overlay (top-left)
        Positioned(
          left: 12,
          top: 12,
          child: MapLegend(
            session: widget.session,
            refSession: refSession,
            appPointsCount: appPoints.length,
            refPointsCount: refPoints.length,
            isTrimmed: _trimReference,
          ),
        ),

        // Controls overlay (top-right)
        Positioned(
          right: 12,
          top: 12,
          child: MapControls(
            hasReference: widget.session.hasReference,
            showAppTrack: _showAppTrack,
            showRefTrack: _showRefTrack,
            showStepMarkers: _showStepMarkers,
            showAccuracyCircles: _showAccuracyCircles,
            isTrimmed: _trimReference,
            onToggleAppTrack: () =>
                setState(() => _showAppTrack = !_showAppTrack),
            onToggleRefTrack: () =>
                setState(() => _showRefTrack = !_showRefTrack),
            onToggleStepMarkers: () =>
                setState(() => _showStepMarkers = !_showStepMarkers),
            onToggleAccuracyCircles: () =>
                setState(() => _showAccuracyCircles = !_showAccuracyCircles),
            onToggleTrim: () =>
                setState(() => _trimReference = !_trimReference),
            onFitBounds: _fitBounds,
          ),
        ),
      ],
    );
  }

  /// Slight darkening so bright satellite imagery doesn't dominate the UI.
  Widget _darkModeTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.85, 0, 0, 0, 0, //
        0, 0.85, 0, 0, 0, //
        0, 0, 0.85, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      child: tileWidget,
    );
  }
}
