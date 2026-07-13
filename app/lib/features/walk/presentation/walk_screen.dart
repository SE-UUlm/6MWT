import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/walk_session.dart';
import 'walk_session_provider.dart';

class WalkScreen extends ConsumerWidget {
  const WalkScreen({super.key});

  String _statusMessage(WalkSessionState state) {
    final errorMessage = state.errorMessage;

    if (errorMessage != null) {
      return errorMessage;
    }

    switch (state.phase) {
      case WalkPhase.idle:
        return 'Test not started';
      case WalkPhase.running:
        return state.currentPosition == null
            ? 'Waiting for GPS positions...'
            : 'Receiving GPS positions';
      case WalkPhase.finished:
        return 'Test finished';
      case WalkPhase.aborted:
        return 'Test stopped';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(walkSessionProvider);
    final state = // Fallback needed because on first frame walkSessionStateProvider does not have a value yet
        ref.watch(walkSessionStateProvider).value ?? session.state;

    final currentPosition = state.currentPosition;

    return Scaffold(
      appBar: AppBar(title: const Text('Walking Test')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Six Minute Walk Test',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 32),

              _InfoCard(title: 'Timer', value: state.formattedRemainingTime),

              const SizedBox(height: 16),

              _InfoCard(
                title: 'Distance',
                value: '${state.distanceMeters.toStringAsFixed(1)} m',
              ),

              const SizedBox(height: 16),

              _InfoCard(title: 'Status', value: _statusMessage(state)),

              const SizedBox(height: 16),

              if (currentPosition != null)
                _InfoCard(
                  title: 'Current Position',
                  value:
                      'Lat: ${currentPosition.latitude.toStringAsFixed(6)}\n'
                      'Lng: ${currentPosition.longitude.toStringAsFixed(6)}\n'
                      'Accuracy: ${currentPosition.accuracy.toStringAsFixed(1)} m',
                )
              else
                const _InfoCard(
                  title: 'Current Position',
                  value: 'No position yet',
                ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: state.isRunning ? null : session.start,
                child: const Text('Start Test'),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: state.isRunning ? session.abort : null,
                child: const Text('Stop Test'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: session.reset,
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
