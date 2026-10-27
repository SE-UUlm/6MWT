import '../domain/sensor_sample.dart';

// A data source that emits timestamped measurements while active.
// Implementations wrap concrete plugins (GPS, pedometer, health APIs, ...);
// consumers (engine, recorder) only ever see [SensorSample]s.
abstract class SensorSource {
  String get sourceId;

  // Broadcast stream of measurements. Only emits between start() and stop().
  Stream<SensorSample> get samples;

  // Throws [SensorUnavailableException] if the source cannot deliver data
  // (e.g. missing permission, disabled hardware).
  Future<void> start();

  Future<void> stop();

  // Sources may override this to provide measurements captured during warm-up
  // or queried when a walk starts.
  Future<List<SensorSample>> getInitialSamples() async => const [];
}

// Why sensor data is missing; lets the UI show a translated message.
enum SensorIssue {
  locationUnavailable,
  activityRecognitionDenied,
  // The source could not be started for another reason.
  unavailable,
  // A running source reported an error.
  streamError,
}

class SensorUnavailableException implements Exception {
  const SensorUnavailableException(
    this.message, {
    this.issue = SensorIssue.unavailable,
  });

  final String message;
  final SensorIssue issue;

  @override
  String toString() => message;
}
