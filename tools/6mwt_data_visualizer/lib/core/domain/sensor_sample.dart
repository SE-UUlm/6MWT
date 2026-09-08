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

enum SampleType {
  position('position'),
  steps('steps'),
  acceleration('acceleration'),
  heartRate('heart_rate');

  const SampleType(this.wireName);

  // The stable string used in the DB, CSV and JSON export.
  final String wireName;

  static SampleType? fromWireName(String wireName) {
    try {
      return values.firstWhere((type) => type.wireName == wireName);
    } catch (_) {
      return null;
    }
  }
}

class SensorSample {
  const SensorSample({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.sourceId,
    required this.values,
  });

  final int id;
  final DateTime timestamp;
  final SampleType type;
  final String sourceId;
  final Map<String, double> values;

  factory SensorSample.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String;
    final type = SampleType.fromWireName(rawType);
    if (type == null) {
      throw FormatException('Unknown sample type: $rawType');
    }

    final rawValues = json['values'] as Map<String, dynamic>;
    final values = rawValues.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return SensorSample(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: type,
      sourceId: json['sourceId'] as String,
      values: values,
    );
  }
}
