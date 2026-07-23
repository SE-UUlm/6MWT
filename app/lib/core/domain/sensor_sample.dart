class SensorSample {
  const SensorSample({
    required this.timestamp,
    required this.type,
    required this.sourceId,
    required this.values,
  });

  final DateTime timestamp;

  // What are we measuring?
  final SampleType type;

  // Where is the measurement coming from, e.g. gps, health_connect
  final String sourceId;

  final Map<String, double> values;
}

enum SampleType {
  position('position'),
  steps('steps'),
  acceleration('acceleration'),
  heartRate('heart_rate');

  const SampleType(this.wireName);

  // The stable string used in the DB, CSV and JSON export.
  final String wireName;

  static SampleType fromWireName(String wireName) =>
      values.firstWhere((type) => type.wireName == wireName);
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

// Value keys used by step samples
abstract final class StepKeys {
  static const cumulativeSteps = 'cumulative_steps';
  static const pedestrianStatus = 'pedestrian_status';
}
