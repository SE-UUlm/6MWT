import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

import '../../core/domain/session.dart';
import '../../core/utils/date_formatters.dart';
import '../chart/distance_steps_chart.dart';
import '../estimator_lab/estimator_lab.dart';
import '../map/session_map.dart';
import 'session_info_panel.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.session});

  final Session session;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  bool _showChart = true;
  bool _showLab = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title bar
        _TitleBar(
          session: session,
          showChart: _showChart,
          onToggleChart: () => setState(() => _showChart = !_showChart),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Recording'),
                icon: Icon(Icons.map_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text('Estimator Lab'),
                icon: Icon(Icons.science_outlined),
              ),
            ],
            selected: {_showLab},
            onSelectionChanged: (selection) =>
                setState(() => _showLab = selection.single),
          ),
        ),
        // Main content: map & chart on the left, info panel on the right
        Expanded(
          // Keep the lab mounted when switching tabs so parameter variants survive.
          child: IndexedStack(
            index: _showLab ? 1 : 0,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side: Map and Chart
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Map view
                        Expanded(
                          flex: _showChart ? 3 : 1,
                          child: SessionMap(
                            session: session,
                            onReferenceSaved: (updated) => ref
                                .read(exportDataProvider.notifier)
                                .replaceSession(session, updated),
                          ),
                        ),
                        // Chart view (Phase 2)
                        if (_showChart) ...[
                          const Divider(height: 1),
                          Expanded(
                            flex: 2,
                            child: DistanceStepsChart(
                              session: session,
                              onClose: () => setState(() => _showChart = false),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Info panel on the right
                  SizedBox(
                    width: 260,
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: SessionInfoPanel(session: session),
                    ),
                  ),
                ],
              ),
              EstimatorLab(session: session),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.session,
    required this.showChart,
    required this.onToggleChart,
  });

  final Session session;
  final bool showChart;
  final VoidCallback onToggleChart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.directions_walk, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    session.notes.isNotEmpty ? session.notes : 'Session',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (session.hasReference) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.watch_outlined,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.references.length} reference(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatDateTime(session.startedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              showChart ? Icons.stacked_line_chart : Icons.show_chart,
              color: showChart
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            tooltip: showChart ? 'Hide chart' : 'Show chart',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleChart,
          ),
        ],
      ),
    );
  }
}
