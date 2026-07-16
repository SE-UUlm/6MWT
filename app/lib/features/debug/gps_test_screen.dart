import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';

class GpsTestScreen extends ConsumerStatefulWidget {
  const GpsTestScreen({super.key});

  @override
  ConsumerState<GpsTestScreen> createState() => _GpsTestScreenState();
}

class _GpsTestScreenState extends ConsumerState<GpsTestScreen> {
  Position? _position;
  String _status = 'No location loaded yet.';
  bool _isLoading = false;

  Future<void> _loadCurrentPosition() async {
    // TODO: Maybe remove this screen because locationServiceProvider violates feature architecture. Or move walk_session etc. to core
    final locationService = ref.read(locationServiceProvider);

    setState(() {
      _isLoading = true;
      _status = 'Checking location permission...';
    });

    final hasPermission = await locationService.requestLocationPermission();

    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _status = 'Location permission or location service missing.';
      });
      return;
    }

    try {
      final position = await locationService.getCurrentPosition();

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
