import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/sensor_sample.dart';
import '../../core/domain/test_session.dart';
import 'test_session_provider.dart';

class WalkingTestScreen extends ConsumerWidget {
  const WalkingTestScreen({super.key});

  String _statusMessage(TestSessionState state) {
    final errorMessage = state.errorMessage;

    if (errorMessage != null) {
      return errorMessage;
    }

    switch (state.phase) {
      case TestPhase.idle:
        return 'Test not started';
      case TestPhase.running:
        return state.lastPosition == null
            ? 'Waiting for GPS positions...'
            : 'Receiving GPS positions';
      case TestPhase.finished:
        return 'Test finished';
      case TestPhase.aborted:
        return 'Test stopped';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(testSessionProvider);
    final state =
        ref.watch(testSessionStateProvider).value ?? session.state;

    final lastPosition = state.lastPosition;

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

              if (state.lastSamples[SampleTypes.heartRate] != null ||
                  state.lastSamples[SampleTypes.spo2] != null) ...[
                _InfoCard(
                  title: 'Vitals',
                  value: [
                    if (state.lastSamples[SampleTypes.heartRate]
                        case final heartRate?)
                      '${heartRate.values[VitalKeys.heartRateBpm]?.toStringAsFixed(0)} bpm',
                    if (state.lastSamples[SampleTypes.spo2] case final spo2?)
                      'SpO2 ${spo2.values[VitalKeys.spo2Percent]?.toStringAsFixed(0)} %',
                  ].join(' · '),
                ),

                const SizedBox(height: 16),
              ],

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
