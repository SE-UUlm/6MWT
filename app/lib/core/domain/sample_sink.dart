import 'sensor_sample.dart';

// Receives every raw sample recorded during a test session. Implemented by
// the persistence layer; the engine only knows this interface.
abstract class SampleSink {
  void addSample(String sessionId, SensorSample sample);
}
