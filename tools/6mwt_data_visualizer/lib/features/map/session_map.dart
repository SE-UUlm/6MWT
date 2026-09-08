import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';
import 'gps_track_layer.dart';
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
        ? (widget.session.trimmedReferenceSession ?? widget.session.referenceSession)
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
    final refPoints = refSession != null ? _gpsPoints(refSession) : const <LatLng>[];

    final allPoints = _allPoints();
    if (allPoints.isEmpty) {
      return const Center(child: Text('Keine GPS-Daten für diese Session.'));
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
            // Esri World Imagery – kostenlos, kein API-Key
            TileLayer(
              urlTemplate:
                  'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'de.uni_ulm.six_mwt_visualizer',
              tileBuilder: _darkModeTileBuilder,
            ),
            // Reference track (drawn below app track so app track stays prominent)
            if (_showRefTrack && refSession != null && refPoints.isNotEmpty)
              GpsTrackLayer(
                session: refSession,
                gpsPoints: refPoints,
                trackColor: const Color(0xFFFF6D00), // Vibrant Orange
                startColor: const Color(0xFFFF9800),
                endColor: const Color(0xFFD84315),
                startLabel: 'Referenz Start',
                endLabel: 'Referenz Ende',
                isReference: true,
                showAccuracyCircles: false,
              ),
            // 6MWT App GPS track
            if (_showAppTrack && appPoints.isNotEmpty)
              GpsTrackLayer(
                session: widget.session,
                gpsPoints: appPoints,
                trackColor: const Color(0xFF42A5F5), // Vibrant Blue
                startColor: Colors.green,
                endColor: Colors.red,
                startLabel: 'App Start',
                endLabel: 'App Ende',
                isReference: false,
                showAccuracyCircles: _showAccuracyCircles,
              ),
            // Step markers for app track (toggleable)
            if (_showStepMarkers && _showAppTrack && appPoints.isNotEmpty)
              StepMarkerLayer(session: widget.session, gpsPoints: appPoints),
            // Esri attribution
            const _EsriAttribution(),
          ],
        ),

        // Map Legend overlay (top-left)
        Positioned(
          left: 12,
          top: 12,
          child: _MapLegend(
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
          child: _MapControls(
            hasReference: widget.session.hasReference,
            showAppTrack: _showAppTrack,
            showRefTrack: _showRefTrack,
            showStepMarkers: _showStepMarkers,
            showAccuracyCircles: _showAccuracyCircles,
            isTrimmed: _trimReference,
            onToggleAppTrack: () => setState(() => _showAppTrack = !_showAppTrack),
            onToggleRefTrack: () => setState(() => _showRefTrack = !_showRefTrack),
            onToggleStepMarkers: () => setState(() => _showStepMarkers = !_showStepMarkers),
            onToggleAccuracyCircles: () =>
                setState(() => _showAccuracyCircles = !_showAccuracyCircles),
            onToggleTrim: () => setState(() => _trimReference = !_trimReference),
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
        0.85, 0, 0, 0, 0,
        0, 0.85, 0, 0, 0,
        0, 0, 0.85, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }
}

// ---------------------------------------------------------------------------
// Controls overlay
// ---------------------------------------------------------------------------

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.hasReference,
    required this.showAppTrack,
    required this.showRefTrack,
    required this.showStepMarkers,
    required this.showAccuracyCircles,
    required this.isTrimmed,
    required this.onToggleAppTrack,
    required this.onToggleRefTrack,
    required this.onToggleStepMarkers,
    required this.onToggleAccuracyCircles,
    required this.onToggleTrim,
    required this.onFitBounds,
  });

  final bool hasReference;
  final bool showAppTrack;
  final bool showRefTrack;
  final bool showStepMarkers;
  final bool showAccuracyCircles;
  final bool isTrimmed;
  final VoidCallback onToggleAppTrack;
  final VoidCallback onToggleRefTrack;
  final VoidCallback onToggleStepMarkers;
  final VoidCallback onToggleAccuracyCircles;
  final VoidCallback onToggleTrim;
  final VoidCallback onFitBounds;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.fit_screen, size: 20),
              tooltip: 'Tracks zentrieren / einpassen',
              onPressed: onFitBounds,
            ),
            const Divider(height: 1),
            IconButton(
              icon: Icon(
                Icons.phone_android,
                size: 20,
                color: showAppTrack ? const Color(0xFF42A5F5) : Colors.grey,
              ),
              tooltip: showAppTrack
                  ? '6MWT App-Track ausblenden'
                  : '6MWT App-Track einblenden',
              onPressed: onToggleAppTrack,
            ),
            if (hasReference) ...[
              IconButton(
                icon: Icon(
                  Icons.track_changes,
                  size: 20,
                  color: showRefTrack ? const Color(0xFFFF6D00) : Colors.grey,
                ),
                tooltip: showRefTrack
                    ? 'Referenz-Track ausblenden'
                    : 'Referenz-Track einblenden',
                onPressed: onToggleRefTrack,
              ),
              IconButton(
                icon: Icon(
                  Icons.content_cut,
                  size: 20,
                  color: isTrimmed ? const Color(0xFFFF6D00) : Colors.grey,
                ),
                tooltip: isTrimmed
                    ? 'Referenz auf 6MWT-Zeitfenster zugeschnitten (Klicken für ungekürzt)'
                    : 'Referenz ungekürzt (Klicken für Zuschnitt auf Testdauer)',
                onPressed: onToggleTrim,
              ),
            ],
            const Divider(height: 1),
            IconButton(
              icon: Icon(
                Icons.directions_walk,
                size: 20,
                color: showStepMarkers ? Colors.blue.shade200 : Colors.grey,
              ),
              tooltip: showStepMarkers
                  ? 'Schritt-Marker ausblenden'
                  : 'Schritt-Marker einblenden',
              onPressed: onToggleStepMarkers,
            ),
            IconButton(
              icon: Icon(
                Icons.adjust,
                size: 20,
                color: showAccuracyCircles ? Colors.blue.shade200 : Colors.grey,
              ),
              tooltip: showAccuracyCircles
                  ? 'Genauigkeitskreise ausblenden'
                  : 'Genauigkeitskreise einblenden',
              onPressed: onToggleAccuracyCircles,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map Legend overlay
// ---------------------------------------------------------------------------

class _MapLegend extends StatelessWidget {
  const _MapLegend({
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
    final deltaDist = refSession != null ? session.distance - refSession!.distance : 0.0;
    final deltaPct = refSession != null && refSession!.distance > 0
        ? ((session.distance - refSession!.distance) / refSession!.distance) * 100
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
                    color: const Color(0xFF42A5F5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '📱 6MWT App: ${session.distance.toStringAsFixed(1)} m ($appPointsCount GPS)',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
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
                      color: const Color(0xFFFF6D00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🎯 Referenz${isTrimmed ? ' (gekürzt)' : ' (voll)'}: ${refSession!.distance.toStringAsFixed(1)} m ($refPointsCount GPS)',
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
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
                  'Δ Distanz: ${deltaDist >= 0 ? '+' : ''}${deltaDist.toStringAsFixed(1)} m (${deltaPct >= 0 ? '+' : ''}${deltaPct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: deltaDist.abs() <= 15 ? Colors.lightGreenAccent : Colors.orangeAccent,
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

// ---------------------------------------------------------------------------
// Esri attribution (required by Esri ToS)
// ---------------------------------------------------------------------------

class _EsriAttribution extends StatelessWidget {
  const _EsriAttribution();

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
