import 'sensor_sample.dart';

// Receives every raw sample recorded during a test session. Implemented by
// the persistence layer; the engine only knows this interface.
abstract class SampleSink {
  // Must not block: high-frequency sources (accelerometer) call this often.
  void addSample(String sessionId, SensorSample sample);

  // Persists everything still buffered. Called by the engine when a test
  // ends.
  Future<void> flush();
}
