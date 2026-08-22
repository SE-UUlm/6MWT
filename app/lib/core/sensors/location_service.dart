import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Checks if location services are enabled and requests permission if needed.
  Future<bool> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // If location services are disabled, GPS cannot be used.
    if (!serviceEnabled) {
      return false;
    }

    // Check current location permission status.
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is denied, ask the user for permission.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If permission is still denied or permanently denied, stop here.
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Permission is granted.
    return true;
  }

  // Gets the current GPS position once.
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // Provides platform-specific location settings for continuous GPS tracking.
  Stream<Position> getPositionStream() {
    final LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,

        // Keeps location tracking active during a walk test when  the app
        // is backgrounded or the screen is locked.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Walk test in progress',
          notificationText: 'Location tracking is active.',
          setOngoing: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
