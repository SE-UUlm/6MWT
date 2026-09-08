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

    return ListTile(
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        session.notes.isNotEmpty ? session.notes : session.id.substring(0, 8),
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(
        '${_formatDate(session.startedAt)}  ·  '
        '${session.distance.toStringAsFixed(0)} m  ·  '
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
