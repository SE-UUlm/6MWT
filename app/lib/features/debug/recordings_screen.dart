import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/data_providers.dart';
import '../../core/data/sample_repository.dart';

final recordingsProvider = StreamProvider<List<RecordingSummary>>(
  (ref) => ref.watch(sampleRepositoryProvider).watchRecordings(),
);

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  Future<void> _export(
    WidgetRef ref,
    RecordingSummary recording, {
    required bool asCsv,
  }) async {
    final repository = ref.read(sampleRepositoryProvider);

    final content = asCsv
        ? await repository.exportSessionAsCsv(recording.sessionId)
        : await repository.exportSessionAsJson(recording.sessionId);

    final directory = await getTemporaryDirectory();
    final extension = asCsv ? 'csv' : 'json';
    final file = File(
      '${directory.path}/6mwt_${recording.sessionId}.$extension',
    );
    await file.writeAsString(content);

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  String _formatDateTime(DateTime dateTime) {
    String pad(int value) => value.toString().padLeft(2, '0');

    return '${pad(dateTime.day)}.${pad(dateTime.month)}.${dateTime.year} '
        '${pad(dateTime.hour)}:${pad(dateTime.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(recordingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recorded Data')),
      body: switch (recordings) {
        AsyncValue(:final value?) when value.isEmpty => const Center(
          child: Text('No recordings yet. Run a test first.'),
        ),
        AsyncValue(:final value?) => ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) {
            final recording = value[index];

            return ListTile(
              title: Text(_formatDateTime(recording.firstSampleAt)),
              subtitle: Text('${recording.sampleCount} samples'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _export(ref, recording, asCsv: true),
                    child: const Text('CSV'),
                  ),
                  TextButton(
                    onPressed: () => _export(ref, recording, asCsv: false),
                    child: const Text('JSON'),
                  ),
                ],
              ),
            );
          },
        ),
        AsyncValue(error: != null) => const Center(
          child: Text('Could not load recordings.'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
