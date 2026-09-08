import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../session_detail/session_detail_screen.dart';
import '../session_list/session_list_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSession = ref.watch(selectedSessionProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left sidebar – Session list
          SizedBox(
            width: 280,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: const SessionListPanel(),
            ),
          ),
          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          // Right – Session detail or empty state
          Expanded(
            child: selectedSession != null
                ? SessionDetailScreen(session: selectedSession)
                : const _EmptyState(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Icon(
            Icons.map_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          Text(
            'Lade eine JSON-Exportdatei\nund wähle eine Session aus.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
