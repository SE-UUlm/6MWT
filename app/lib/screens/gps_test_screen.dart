import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

class GpsTestScreen extends StatefulWidget {
  const GpsTestScreen({super.key});

  @override
  State<GpsTestScreen> createState() => _GpsTestScreenState();
}

class _GpsTestScreenState extends State<GpsTestScreen> {
  final LocationService _locationService = LocationService();

  Position? _position;
  String _status = 'No location loaded yet.';
  bool _isLoading = false;

  Future<void> _loadCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking location permission...';
    });

    final hasPermission = await _locationService.requestLocationPermission();

    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _status = 'Location permission or location service missing.';
      });
      return;
    }

    try {
      final position = await _locationService.getCurrentPosition();

      setState(() {
        _position = position;
        _status = 'Location loaded.';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _status = 'Could not load location: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;

    return Scaffold(
      appBar: AppBar(title: const Text('GPS Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 24),

            if (_isLoading) const CircularProgressIndicator(),

            if (position != null) ...[
              Text('Latitude: ${position.latitude}'),
              Text('Longitude: ${position.longitude}'),
              Text('Accuracy: ${position.accuracy.toStringAsFixed(1)} m'),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadCurrentPosition,
                child: const Text('Get current GPS position'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
