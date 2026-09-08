import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Map overlay controls for toggling track visibility and fitting bounds.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
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
              tooltip: 'Center / fit tracks',
              onPressed: onFitBounds,
            ),
            const Divider(height: 1),
            IconButton(
              icon: Icon(
                Icons.phone_android,
                size: 20,
                color: showAppTrack ? AppColors.appTrackBlue : Colors.grey,
              ),
              tooltip: showAppTrack
                  ? 'Hide 6MWT app track'
                  : 'Show 6MWT app track',
              onPressed: onToggleAppTrack,
            ),
            if (hasReference) ...[
              IconButton(
                icon: Icon(
                  Icons.track_changes,
                  size: 20,
                  color:
                      showRefTrack ? AppColors.referenceOrange : Colors.grey,
                ),
                tooltip: showRefTrack
                    ? 'Hide reference track'
                    : 'Show reference track',
                onPressed: onToggleRefTrack,
              ),
              IconButton(
                icon: Icon(
                  Icons.content_cut,
                  size: 20,
                  color: isTrimmed ? AppColors.referenceOrange : Colors.grey,
                ),
                tooltip: isTrimmed
                    ? 'Reference trimmed to 6MWT time window (Click for full)'
                    : 'Reference untrimmed (Click to trim to test duration)',
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
                  ? 'Hide step markers'
                  : 'Show step markers',
              onPressed: onToggleStepMarkers,
            ),
            IconButton(
              icon: Icon(
                Icons.adjust,
                size: 20,
                color:
                    showAccuracyCircles ? Colors.blue.shade200 : Colors.grey,
              ),
              tooltip: showAccuracyCircles
                  ? 'Hide accuracy circles'
                  : 'Show accuracy circles',
              onPressed: onToggleAccuracyCircles,
            ),
          ],
        ),
      ),
    );
  }
}
