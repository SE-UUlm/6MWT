import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Six Minute Walk Test')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/walk'),
              child: const Text('Start Walking Test'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => context.push('/debug/gps'),
              child: const Text('GPS Debug'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _exportData(context, ref),
              icon: const Icon(Icons.share),
              label: const Text('Export All Data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final sessions = await ref
          .read(walkSessionRepositoryProvider)
          .exportAllSessions();
      final samplesBySession = await ref
          .read(sampleRepositoryProvider)
          .exportAllSessions();
      final profiles = await ref
          .read(profileRepositoryProvider)
          .exportAllProfiles();

      // Nest samples inside their respective session.
      for (final session in sessions) {
        final sessionId = session['id'] as String;
        session['samples'] = samplesBySession[sessionId] ?? [];
      }

      final export = {
        'exportedAt': DateTime.now().toIso8601String(),
        'profiles': profiles,
        'sessions': sessions,
      };

      final jsonString = const JsonEncoder().convert(export);

      // Write to a temp file so the share-sheet can attach it.
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/6mwt_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}
