import '../domain/sensor_sample.dart';

// A data source that emits timestamped measurements while active.
// Implementations wrap concrete plugins (GPS, pedometer, health APIs, ...);
// consumers (engine, recorder) only ever see [SensorSample]s.
abstract class SensorSource {
  String get id;

  // Broadcast stream of measurements. Only emits between start() and stop().
  Stream<SensorSample> get samples;

  // Throws [SensorUnavailableException] if the source cannot deliver data
  // (e.g. missing permission, disabled hardware).
  Future<void> start();

  Future<void> stop();
}

class SensorUnavailableException implements Exception {
  const SensorUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
