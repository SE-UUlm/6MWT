import 'package:flutter/material.dart';

import '../../core/domain/session.dart';

class SessionListTile extends StatelessWidget {
  const SessionListTile({
    super.key,
    required this.session,
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  final Session session;
  final Profile? profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final posCount = session.positionSamples.length;

    final refSession = session.referenceSession;
    final distText = refSession != null
        ? '${session.distance.toStringAsFixed(0)} m (Ref: ${refSession.distance.toStringAsFixed(0)} m)'
        : '${session.distance.toStringAsFixed(0)} m';

    return ListTile(
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Expanded(
            child: Text(
              session.notes.isNotEmpty ? session.notes : session.id.substring(0, 8),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (session.hasReference) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.deepOrange.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.track_changes, size: 12, color: Colors.deepOrange),
                  SizedBox(width: 3),
                  Text(
                    'Reference',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${_formatDate(session.startedAt)}  ·  '
        '$distText  ·  '
        '$posCount GPS  ·  ${session.stepSamples.length} Steps',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _PhaseBadge(phase: session.phase),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});
  final String phase;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (phase) {
      'finished' => (Colors.green, Icons.check_circle_outline),
      'aborted' => (Colors.orange, Icons.cancel_outlined),
      _ => (Colors.grey, Icons.help_outline),
    };

    return Icon(icon, color: color, size: 18);
  }
}
