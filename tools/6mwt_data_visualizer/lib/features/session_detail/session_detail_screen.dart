import 'package:flutter/material.dart';

import '../../core/domain/session.dart';
import 'session_info_panel.dart';
import '../map/session_map.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title bar
        _TitleBar(session: session),
        // Main content: map + info side by side
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map takes most space
              Expanded(
                flex: 3,
                child: SessionMap(session: session),
              ),
              // Info panel on the right
              SizedBox(
                width: 260,
                child: Material(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerLow,
                  child: SessionInfoPanel(session: session),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.directions_walk,
              color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              session.notes.isNotEmpty ? session.notes : 'Session',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatDateTime(session.startedAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
