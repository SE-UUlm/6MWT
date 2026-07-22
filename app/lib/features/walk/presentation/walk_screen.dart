import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';

import '../domain/walk_session.dart';
import '../domain/walk_session_provider.dart';

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
        return state.lastSamples[SampleType.position] == null
            ? 'Waiting for GPS positions...'
            : 'Receiving GPS positions';
      case WalkPhase.finished:
        return 'Test finished';
      case WalkPhase.aborted:
        return 'Test stopped';
    }
  }

  String _assessmentMessage(WalkSessionState state, WalkSession session) {
    if (session.walkDuration - state.remainingTime > Duration.zero) {
      final assessment = assessFitness(
        duration: session.walkDuration - state.remainingTime,
        distanceInMeters: state.distanceMeters,
        ageInYears: 27,
        heightInCm: 189.0,
      );

      return 'Percentage: ${assessment.percentOfExpected.round().toString()} %\nCategory: ${assessment.category.name}';
    } else {
      return 'Not started yet';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(walkSessionProvider);
    final state = // Fallback needed because on first frame walkSessionStateProvider does not have a value yet
        ref.watch(walkSessionStateProvider).value ?? session.state;

    final lastPosition = state.lastSamples[SampleType.position];

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

              if (lastPosition != null)
                _InfoCard(
                  title: 'Current Position',
                  value:
                      'Lat: ${lastPosition.values[PositionKeys.latitude]?.toStringAsFixed(6)}\n'
                      'Lng: ${lastPosition.values[PositionKeys.longitude]?.toStringAsFixed(6)}\n'
                      'Accuracy: ${lastPosition.values[PositionKeys.accuracy]?.toStringAsFixed(1)} m',
                )
              else
                const _InfoCard(
                  title: 'Current Position',
                  value: 'No position yet',
                ),

              const SizedBox(height: 16),

              _InfoCard(
                title: 'Assessment:',
                value: _assessmentMessage(state, session),
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
