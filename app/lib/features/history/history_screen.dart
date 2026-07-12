import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data_providers.dart';
import '../../core/data/database.dart';

final testResultsProvider = StreamProvider<List<TestResult>>(
  (ref) => ref.watch(testRepositoryProvider).watchResults(),
);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDateTime(DateTime dateTime) {
    String pad(int value) => value.toString().padLeft(2, '0');

    return '${pad(dateTime.day)}.${pad(dateTime.month)}.${dateTime.year} '
        '${pad(dateTime.hour)}:${pad(dateTime.minute)}';
  }

  String _formatDuration(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(testResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: switch (results) {
        AsyncValue(:final value?) when value.isEmpty => const Center(
          child: Text('No tests recorded yet.'),
        ),
        AsyncValue(:final value?) => ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) {
            final result = value[index];

            return ListTile(
              leading: Icon(
                result.completed ? Icons.check_circle : Icons.cancel_outlined,
                color: result.completed ? Colors.green : Colors.orange,
              ),
              title: Text('${result.distanceMeters.toStringAsFixed(1)} m'),
              subtitle: Text(
                '${_formatDateTime(result.startedAt)} · '
                '${_formatDuration(result.durationSeconds)} min · '
                '${result.completed ? 'completed' : 'aborted'}',
              ),
            );
          },
        ),
        AsyncValue(error: != null) => const Center(
          child: Text('Could not load history.'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
