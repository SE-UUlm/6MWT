import 'package:flutter/material.dart';

import '../../core/domain/session.dart';

class SessionInfoPanel extends StatelessWidget {
  const SessionInfoPanel({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final totalSteps = session.totalSteps;
    final posCount = session.positionSamples.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          _SectionHeader('Übersicht'),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Phase',
            value: session.phase,
            valueColor: _phaseColor(session.phase),
          ),
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'Dauer',
            value: _formatDuration(session.duration),
          ),
          _InfoRow(
            icon: Icons.straighten,
            label: 'Distanz (gespeichert)',
            value: '${session.distance.toStringAsFixed(1)} m',
          ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Start',
            value: _formatDateTime(session.startedAt),
          ),
          if (session.notes.isNotEmpty)
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'Notizen',
              value: session.notes,
            ),
          const SizedBox(height: 12),
          _SectionHeader('Sensordaten'),
          _InfoRow(
            icon: Icons.gps_fixed,
            label: 'GPS-Punkte',
            value: '$posCount',
          ),
          if (totalSteps != null)
            _InfoRow(
              icon: Icons.directions_walk,
              label: 'Schritte (Session)',
              value: '$totalSteps',
            ),
          _InfoRow(
            icon: Icons.sensors,
            label: 'Samples gesamt',
            value: '${session.samples.length}',
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _phaseColor(String phase) => switch (phase) {
        'finished' => Colors.green,
        'aborted' => Colors.orange,
        _ => Colors.grey,
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
