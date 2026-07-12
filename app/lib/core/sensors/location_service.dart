import 'dart:io';

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

  // Provides continuous GPS updates for tracking. The platform-specific
  // settings keep the stream alive while the app is in the background or the
  // screen is locked (Android: geolocator's foreground service with a
  // notification; iOS: background location updates).
  Stream<Position> getPositionStream() {
    late final LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Six Minute Walk Test',
          notificationText: 'The walk test is running.',
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
          // Keeps the CPU awake so the test timer keeps ticking with the
          // screen off.
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
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
