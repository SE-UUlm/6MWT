import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';
import '../../core/domain/haversine.dart';
import '../../core/domain/manual_reference.dart';
import '../../core/data/session_loader.dart';
import '../../core/theme/reference_colors.dart';
import '../../core/theme/app_colors.dart';
import 'gps_track_layer.dart';
import 'map_controls.dart';
import 'map_legend.dart';
import 'step_marker_layer.dart';

const _arcGisAccessToken = String.fromEnvironment('ARCGIS_ACCESS_TOKEN');
const _anonymousArcGisTileUrl =
    'https://services.arcgisonline.com/arcgis/rest/services/'
    'World_Imagery/MapServer/tile/{z}/{y}/{x}';
const _authenticatedArcGisTileUrl =
    'https://ibasemaps-api.arcgis.com/arcgis/rest/services/'
    'World_Imagery/MapServer/tile/{z}/{y}/{x}?token={accessToken}';

class SessionMap extends StatefulWidget {
  const SessionMap({
    super.key,
    required this.session,
    this.onReferenceSaved,
    this.tileProvider,
  });

  final Session session;
  final TileProvider? tileProvider;
  final ValueChanged<Session>? onReferenceSaved;

  @override
  State<SessionMap> createState() => _SessionMapState();
}

class _SessionMapState extends State<SessionMap> {
  final _mapController = MapController();
  late final _tileProvider = widget.tileProvider ?? NetworkTileProvider();
  bool _showAppTrack = true;
  bool _showRefTrack = true;
  bool _showStepMarkers = true;
  bool _showAccuracyCircles = true;
  bool _trimReference = true;
  bool _drawing = false;
  bool _saving = false;
  final _draft = <LatLng>[];
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SessionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      _drawing = false;
      _draft.clear();
      _fitBounds();
    }
  }

  List<Session> get _effectiveReferences => _trimReference
      ? widget.session.trimmedReferences
      : widget.session.references;

  Future<void> _saveReference() async {
    final original = widget.session;
    final onSaved = widget.onReferenceSaved;
    setState(() => _saving = true);
    try {
      final reference = createManualReference(
        widget.session,
        _draft,
        _name.text,
      );
      final updated = await SessionLoader.saveReference(
        widget.session,
        reference,
      );
      if (!mounted) return;
      onSaved?.call(updated);
      if (widget.session.id != original.id) return;
      setState(() {
        _drawing = false;
        _draft.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reference saved.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save reference: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double get _draftDistance {
    var distance = 0.0;
    for (var i = 1; i < _draft.length; i++) {
      distance += haversineDistance(
        lat1: _draft[i - 1].latitude,
        lon1: _draft[i - 1].longitude,
        lat2: _draft[i].latitude,
        lon2: _draft[i].longitude,
      );
    }
    return distance;
  }

  Widget _drawingToolbar() => Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Click the map to add points · ${_draft.length} points · ${_draftDistance.toStringAsFixed(1)} m',
          ),
          const Text(
            'Timing assumes constant speed over the recording.',
            style: TextStyle(fontSize: 11),
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Reference name',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Undo last point',
                icon: const Icon(Icons.undo),
                onPressed: _saving || _draft.isEmpty
                    ? null
                    : () => setState(() => _draft.removeLast()),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _drawing = false;
                        _draft.clear();
                      }),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed:
                    _saving ||
                        _draft.length < 2 ||
                        _draftDistance <= 0 ||
                        _name.text.trim().isEmpty
                    ? null
                    : _saveReference,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save reference'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  List<LatLng> _allPoints() {
    final points = <LatLng>[];
    points.addAll(_gpsPoints(widget.session));
    for (final ref in _effectiveReferences) {
      points.addAll(_gpsPoints(ref));
    }
    return points;
  }

  void _fitBounds() {
    final points = _allPoints();
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
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
    final references = _effectiveReferences;
    final allPoints = _allPoints();
    final bounds = allPoints.isEmpty
        ? null
        : LatLngBounds.fromPoints(allPoints);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            onTap: (_, point) {
              if (_drawing && !_saving) setState(() => _draft.add(point));
            },
            interactionOptions: InteractionOptions(
              // Keep tap recognition stable when entering/leaving drawing mode.
              // Scroll/pinch zoom remains available; double-clicks add points.
              flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
            ),
            initialCenter: const LatLng(48.4, 10),
            initialZoom: 5,
            initialCameraFit: bounds == null
                ? null
                : CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(60),
                  ),
          ),
          children: [
            // Esri World Imagery. For reliable access, provide an ArcGIS token
            // through --dart-define=ARCGIS_ACCESS_TOKEN=...
            TileLayer(
              urlTemplate: _arcGisAccessToken.isEmpty
                  ? _anonymousArcGisTileUrl
                  : _authenticatedArcGisTileUrl,
              additionalOptions: {
                if (_arcGisAccessToken.isNotEmpty)
                  'accessToken': _arcGisAccessToken,
              },
              tileProvider: _tileProvider,
              userAgentPackageName: 'de.uni_ulm.six_mwt_visualizer',
              panBuffer: 0,
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('Failed to load an ArcGIS tile: $error');
              },
              tileBuilder: _darkModeTileBuilder,
            ),
            // Reference track (drawn below app track)
            for (var i = 0; i < references.length; i++)
              if (_showRefTrack && references[i].positionSamples.isNotEmpty)
                GpsTrackLayer(
                  session: references[i],
                  gpsPoints: _gpsPoints(references[i]),
                  trackColor: referenceColor(i),
                  startColor: referenceColor(i),
                  endColor: referenceColor(i),
                  startLabel: '${widget.session.referenceLabel(i)} Start',
                  endLabel: '${widget.session.referenceLabel(i)} End',
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
              StepMarkerLayer(session: widget.session, gpsPoints: appPoints),
            if (_drawing && _draft.isNotEmpty) ...[
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _draft,
                    color: Colors.yellowAccent,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _draft.length; i++)
                    Marker(
                      point: _draft[i],
                      width: 24,
                      height: 24,
                      child: CircleAvatar(
                        backgroundColor: Colors.yellowAccent,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
            references: references,
            appPointsCount: appPoints.length,
            isTrimmed: _trimReference,
          ),
        ),

        Positioned(
          left: 12,
          right: 64,
          bottom: 28,
          child: _drawing
              ? _drawingToolbar()
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed:
                        widget.session.referenceDirectory == null ||
                            widget.onReferenceSaved == null
                        ? null
                        : () => setState(() {
                            _drawing = true;
                            _name.text =
                                'Manual reference ${widget.session.references.length + 1}';
                          }),
                    icon: const Icon(Icons.edit_location_alt),
                    label: const Text('Draw reference'),
                  ),
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
