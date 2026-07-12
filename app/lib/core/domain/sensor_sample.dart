// One timestamped measurement from any sensor source. The generic value map
// lets every source (GPS, steps, heart rate, ...) use the same pipeline and
// makes raw-data recording/export source-independent.
class SensorSample {
  const SensorSample({
    required this.timestamp,
    required this.sensorId,
    required this.type,
    required this.values,
  });

  final DateTime timestamp;

  // Which source produced the sample, e.g. "gps".
  final String sensorId;

  // What kind of measurement this is, see [SampleTypes].
  final String type;

  final Map<String, double> values;
}

abstract final class SampleTypes {
  static const position = 'position';
  static const steps = 'steps';
  static const accelerometer = 'accelerometer';
  static const heartRate = 'heart_rate';
  static const spo2 = 'spo2';
}

// Value keys used by position samples.
abstract final class PositionKeys {
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const accuracy = 'accuracy';
  static const altitude = 'altitude';
  static const speed = 'speed';
  static const heading = 'heading';
}

// Value keys used by step samples. The count is cumulative since device
// boot (as delivered by the platform); per-test deltas are aggregator work.
abstract final class StepKeys {
  static const cumulativeSteps = 'cumulative_steps';
}

// Value keys used by accelerometer samples (m/s², including gravity).
abstract final class AccelerometerKeys {
  static const x = 'x';
  static const y = 'y';
  static const z = 'z';
}

// Value keys used by vital-sign samples from health APIs or wearables.
abstract final class VitalKeys {
  static const heartRateBpm = 'bpm';
  static const spo2Percent = 'percent';
}
