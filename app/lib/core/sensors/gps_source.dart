import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../app/log.dart';
import '../domain/sensor_sample.dart';
import 'location_service.dart';
import 'sensor_source.dart';

final _log = appLogger('GpsSource');

class GpsSource implements SensorSource {
  GpsSource({required this._locationService});

  static const id = 'gps';

  final LocationService _locationService;

  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();

  StreamSubscription<Position>? _subscription;

  @override
  String get sourceId => id;

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    final hasPermission = await _locationService.requestLocationPermission();

    if (!hasPermission) {
      _log.e('Location permission denied or GPS disabled');
      throw const SensorUnavailableException(
        'Location permission denied or GPS disabled',
      );
    }

    _subscription = _locationService.getPositionStream().listen(
      (position) => _controller.add(_toSample(position)),
      onError: (Object error, StackTrace stack) {
        _log.e('GPS stream error', error: error, stackTrace: stack);
        _controller.addError(error, stack);
      },
    );
    _log.i('GPS position stream started');
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _log.d('GPS position stream stopped');
  }

  @override
  Future<List<SensorSample>> getInitialSamples() async {
    final position = await _locationService.getCurrentPosition();
    return [_toSample(position)];
  }

  SensorSample _toSample(Position position) {
    return SensorSample(
      timestamp: position.timestamp.toUtc(),
      sourceId: sourceId,
      type: SampleType.position,
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
