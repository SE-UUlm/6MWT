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
  bool _showStepMarkers = true;

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

  void _fitBounds() {
    final points = _gpsPoints(widget.session);
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
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
    final points = _gpsPoints(widget.session);
    if (points.isEmpty) {
      return const Center(child: Text('Keine GPS-Daten für diese Session.'));
    }

    final bounds = LatLngBounds.fromPoints(points);

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
            // GPS track
            GpsTrackLayer(session: widget.session, gpsPoints: points),
            // Step markers (toggleable)
            if (_showStepMarkers)
              StepMarkerLayer(session: widget.session, gpsPoints: points),
            // Esri attribution
            const _EsriAttribution(),
          ],
        ),
        // Controls overlay
        Positioned(
          right: 12,
          top: 12,
          child: _MapControls(
            showStepMarkers: _showStepMarkers,
            onToggleStepMarkers: () {
              setState(() => _showStepMarkers = !_showStepMarkers);
            },
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
    required this.showStepMarkers,
    required this.onToggleStepMarkers,
    required this.onFitBounds,
  });

  final bool showStepMarkers;
  final VoidCallback onToggleStepMarkers;
  final VoidCallback onFitBounds;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.fit_screen, size: 20),
              tooltip: 'Track einpassen',
              onPressed: onFitBounds,
            ),
            const Divider(height: 1),
            IconButton(
              icon: Icon(
                Icons.directions_walk,
                size: 20,
                color: showStepMarkers ? null : Colors.grey,
              ),
              tooltip: showStepMarkers
                  ? 'Schritt-Marker ausblenden'
                  : 'Schritt-Marker einblenden',
              onPressed: onToggleStepMarkers,
            ),
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
