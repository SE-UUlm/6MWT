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
          if (session.profile != null) ...[
            const SizedBox(height: 10),
            _SectionHeader('Teilnehmer'),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: session.profile!.name,
            ),
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Alter / Größe',
              value: '${session.profile!.age} Jahre · ${session.profile!.height} cm',
            ),
          ],
          const SizedBox(height: 10),
          _SectionHeader('Sensordaten (App)'),
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
          const SizedBox(height: 10),
          _SectionHeader('Referenzvergleich'),
          _ReferenceComparisonCard(session: session),
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

class _ReferenceComparisonCard extends StatefulWidget {
  const _ReferenceComparisonCard({required this.session});

  final Session session;

  @override
  State<_ReferenceComparisonCard> createState() => _ReferenceComparisonCardState();
}

class _ReferenceComparisonCardState extends State<_ReferenceComparisonCard> {
  bool _trimmed = true;

  @override
  Widget build(BuildContext context) {
    if (!widget.session.hasReference) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Keine Referenzdaten (reference.json) vorhanden.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final ref = _trimmed
        ? (widget.session.trimmedReferenceSession ?? widget.session.referenceSession!)
        : widget.session.referenceSession!;

    final deltaDist = widget.session.distance - ref.distance;
    final deltaDistPct = ref.distance > 0 ? (deltaDist / ref.distance) * 100 : 0.0;

    final appSteps = widget.session.totalSteps;
    final refSteps = ref.totalSteps;
    final deltaSteps = (appSteps != null && refSteps != null) ? appSteps - refSteps : null;

    final deltaDuration = widget.session.duration - ref.duration;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.deepOrange.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, size: 16, color: Colors.deepOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Referenzmessung',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => setState(() => _trimmed = !_trimmed),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _trimmed
                        ? Colors.deepOrange.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _trimmed ? Colors.deepOrange : Colors.grey,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _trimmed ? Icons.content_cut : Icons.all_inclusive,
                        size: 11,
                        color: _trimmed ? Colors.deepOrange : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _trimmed ? 'Gekürzt' : 'Voll',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _trimmed ? Colors.deepOrange : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _trimmed
                ? 'Auf 6MWT-Zeitfenster zugeschnitten (+1 Puffer)'
                : 'Gesamte Aufzeichnung ungekürzt',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),

          // Distanz
          _MetricComparisonRow(
            label: 'Distanz',
            appValue: '${widget.session.distance.toStringAsFixed(1)} m',
            refValue: '${ref.distance.toStringAsFixed(1)} m',
            deltaText:
                '${deltaDist >= 0 ? '+' : ''}${deltaDist.toStringAsFixed(1)} m (${deltaDistPct >= 0 ? '+' : ''}${deltaDistPct.toStringAsFixed(1)}%)',
            deltaColor: deltaDist.abs() <= 15 ? Colors.green : Colors.orange.shade800,
          ),

          const Divider(height: 12),

          // Schritte
          if (appSteps != null || refSteps != null) ...[
            _MetricComparisonRow(
              label: 'Schritte',
              appValue: appSteps != null ? '$appSteps' : '–',
              refValue: refSteps != null ? '$refSteps' : '–',
              deltaText: deltaSteps != null
                  ? '${deltaSteps >= 0 ? '+' : ''}$deltaSteps'
                  : null,
              deltaColor: (deltaSteps != null && deltaSteps.abs() <= 20)
                  ? Colors.green
                  : Colors.orange.shade800,
            ),
            const Divider(height: 12),
          ],

          // Dauer
          _MetricComparisonRow(
            label: 'Dauer',
            appValue: '${widget.session.duration}s',
            refValue: '${ref.duration}s',
            deltaText: '${deltaDuration >= 0 ? '+' : ''}${deltaDuration}s',
            deltaColor: deltaDuration.abs() <= 5 ? Colors.green : Colors.orange.shade800,
          ),

          const Divider(height: 12),

          // GPS Punkte
          _MetricComparisonRow(
            label: 'GPS-Punkte',
            appValue: '${widget.session.positionSamples.length}',
            refValue: '${ref.positionSamples.length}',
            deltaText: null,
          ),
        ],
      ),
    );
  }
}

class _MetricComparisonRow extends StatelessWidget {
  const _MetricComparisonRow({
    required this.label,
    required this.appValue,
    required this.refValue,
    this.deltaText,
    this.deltaColor,
  });

  final String label;
  final String appValue;
  final String refValue;
  final String? deltaText;
  final Color? deltaColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (deltaText != null)
              Text(
                'Δ: $deltaText',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: deltaColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                'App: $appValue',
                style: const TextStyle(fontSize: 11, color: Color(0xFF1E88E5)),
              ),
            ),
            Expanded(
              child: Text(
                'Ref: $refValue',
                style: const TextStyle(fontSize: 11, color: Color(0xFFE65100)),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
