import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/sensor_sample.dart';
import 'location_service.dart';
import 'sensor_source.dart';

class GpsSource implements SensorSource {
  GpsSource({required this._locationService});

  static const sourceId = 'gps';

  final LocationService _locationService;

  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();

  StreamSubscription<Position>? _subscription;

  @override
  String get id => sourceId;

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    final hasPermission = await _locationService.requestLocationPermission();

    if (!hasPermission) {
      throw const SensorUnavailableException(
        'Location permission denied or GPS disabled',
      );
    }

    _subscription = _locationService.getPositionStream().listen(
      (position) => _controller.add(_toSample(position)),
      onError: _controller.addError,
    );
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  SensorSample _toSample(Position position) {
    return SensorSample(
      timestamp: position.timestamp,
      sensorId: sourceId,
      type: SampleTypes.position,
      values: {
        PositionKeys.latitude: position.latitude,
        PositionKeys.longitude: position.longitude,
        PositionKeys.accuracy: position.accuracy,
        PositionKeys.altitude: position.altitude,
        PositionKeys.speed: position.speed,
        PositionKeys.heading: position.heading,
      },
    );
  }
}
