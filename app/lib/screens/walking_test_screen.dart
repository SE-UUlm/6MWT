import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:six_minute_walk_test/services/distance_calculator.dart';
import 'package:six_minute_walk_test/services/location_service.dart';

class WalkingTestScreen extends StatefulWidget {
  const WalkingTestScreen({super.key});

  @override
  State<WalkingTestScreen> createState() => _WalkingTestScreenState();
}

class _WalkingTestScreenState extends State<WalkingTestScreen> {
  static const int _initialSeconds = 360; // 6 minutes in seconds

  final LocationService _locationService = LocationService();
  final DistanceCalculator _distanceCalculator = DistanceCalculator();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _testTimer;

  Position? _currentPosition;
  double _distanceInMeters = 0;
  int _remainingSeconds = _initialSeconds;
  bool _isRunning = false;
  String _statusMessage = 'Test not started';

  Future<void> _startTest() async {
    final hasPermission = await _locationService.requestLocationPermission();

    if (!hasPermission) {
      setState(() {
        _statusMessage = 'Location permission denied or GPS disabled';
      });
      return;
    }

    _distanceCalculator.reset();
    _positionSubscription?.cancel();
    _testTimer?.cancel();

    setState(() {
      _isRunning = true;
      _distanceInMeters = 0;
      _remainingSeconds = _initialSeconds;
      _currentPosition = null;
      _statusMessage = 'Waiting for GPS positions...';
    });

    _startTimer();
    _startLocationStream();
  }

  void _startTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        _finishTest();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _startLocationStream() {
    _positionSubscription = _locationService.getPositionStream().listen(
      (position) {
        _distanceCalculator.addPosition(position);

        setState(() {
          _currentPosition = position;
          _distanceInMeters = _distanceCalculator.totalDistance;
          _statusMessage = 'Receiving GPS positions';
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'Location error: $error';
        });
      },
    );
  }

  void _finishTest() {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    _testTimer?.cancel();
    _testTimer = null;

    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
      _statusMessage = 'Test finished';
    });
  }

  void _stopTest() {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    _testTimer?.cancel();
    _testTimer = null;

    setState(() {
      _isRunning = false;
      _statusMessage = 'Test stopped';
    });
  }

  void _resetTest() {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    _testTimer?.cancel();
    _testTimer = null;

    _distanceCalculator.reset();

    setState(() {
      _isRunning = false;
      _distanceInMeters = 0;
      _remainingSeconds = _initialSeconds;
      _currentPosition = null;
      _statusMessage = 'Test reset';
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _testTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = _currentPosition;

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

              _InfoCard(title: 'Timer', value: _formattedTime),

              const SizedBox(height: 16),

              _InfoCard(
                title: 'Distance',
                value: '${_distanceInMeters.toStringAsFixed(1)} m',
              ),

              const SizedBox(height: 16),

              _InfoCard(title: 'Status', value: _statusMessage),

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
                onPressed: _isRunning ? null : _startTest,
                child: const Text('Start Test'),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isRunning ? _stopTest : null,
                child: const Text('Stop Test'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(onPressed: _resetTest, child: const Text('Reset')),
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
