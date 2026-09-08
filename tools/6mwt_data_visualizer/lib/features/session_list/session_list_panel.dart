import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/export_data.dart';
import '../../providers/providers.dart';
import 'session_list_tile.dart';

class SessionListPanel extends ConsumerStatefulWidget {
  const SessionListPanel({super.key});

  @override
  ConsumerState<SessionListPanel> createState() => _SessionListPanelState();
}

class _SessionListPanelState extends ConsumerState<SessionListPanel> {
  @override
  void initState() {
    super.initState();
    // Auto-detect and load default JSON on startup
    _tryAutoLoad();
  }

  Future<void> _tryAutoLoad() async {
    final files = await ref.read(defaultJsonFilesProvider.future);
    if (files.isNotEmpty && mounted) {
      await ref
          .read(exportDataProvider.notifier)
          .loadFromPath(files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportDataProvider);
    final selectedSession = ref.watch(selectedSessionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          onPickFolder: () async {
            await ref.read(exportDataProvider.notifier).pickDirectoryAndLoad();
          },
          onPickFile: () async {
            await ref.read(exportDataProvider.notifier).pickAndLoad();
          },
          onReload: () async {
            await _tryAutoLoad();
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: exportState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorView(error: err.toString()),
            data: (exportData) {
              if (exportData == null) {
                return const _NoDataView();
              }
              return _SessionList(
                exportData: exportData,
                selectedId: selectedSession?.id,
                onSelect: (session) {
                  ref.read(selectedSessionProvider.notifier).select(session);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header with title and file-open button
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.onPickFolder,
    required this.onPickFile,
    required this.onReload,
  });

  final VoidCallback onPickFolder;
  final VoidCallback onPickFile;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '6MWT Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Neu laden',
            onPressed: onReload,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined, size: 20),
            tooltip: 'Ordner öffnen',
            onPressed: onPickFolder,
          ),
          IconButton(
            icon: const Icon(Icons.file_open_outlined, size: 20),
            tooltip: 'JSON-Datei öffnen',
            onPressed: onPickFile,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session list
// ---------------------------------------------------------------------------

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.exportData,
    required this.selectedId,
    required this.onSelect,
  });

  final ExportData exportData;
  final String? selectedId;
  final void Function(dynamic session) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: exportData.sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final session = exportData.sessions[index];
        return SessionListTile(
          session: session,
          profile: exportData.profileForSession(session),
          isSelected: session.id == selectedId,
          onTap: () => onSelect(session),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Keine Datei geladen.\nKlicke auf das Ordner-Symbol.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error, size: 40),
          const SizedBox(height: 8),
          Text('Fehler beim Laden:\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}
