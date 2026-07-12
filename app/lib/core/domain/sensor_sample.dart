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
