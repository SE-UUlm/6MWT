import 'sensor_sample.dart';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.height,
    required this.age,
  });

  final int id;
  final String name;
  final DateTime timestamp;
  final int height;
  final int age;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      height: json['height'] as int,
      age: json['age'] as int,
    );
  }
}

class Session {
  const Session({
    required this.id,
    required this.notes,
    required this.startedAt,
    required this.duration,
    required this.distance,
    required this.phase,
    required this.profileId,
    required this.samples,
  });

  final String id;
  final String notes;
  final DateTime startedAt;
  final int duration; // seconds
  final double distance; // meters
  final String phase;
  final int profileId;
  final List<SensorSample> samples;

  /// All GPS position samples, in order.
  List<SensorSample> get positionSamples =>
      samples.where((s) => s.type == SampleType.position).toList();

  /// All step samples that contain cumulative_steps.
  List<SensorSample> get stepSamples => samples
      .where(
        (s) =>
            s.type == SampleType.steps &&
            s.values.containsKey(StepKeys.cumulativeSteps),
      )
      .toList();

  /// Total steps walked during the session.
  int? get totalSteps {
    final steps = stepSamples;
    if (steps.isEmpty) return null;
    final values = steps.map((s) => s.values[StepKeys.cumulativeSteps]!);
    return (values.last - values.first).round();
  }

  /// Cumulative steps count at a given timestamp (nearest sample at or before).
  double? stepsAtTime(DateTime time) {
    SensorSample? nearest;
    for (final sample in stepSamples) {
      if (sample.timestamp.isBefore(time) ||
          sample.timestamp.isAtSameMomentAs(time)) {
        nearest = sample;
      } else {
        break;
      }
    }
    return nearest?.values[StepKeys.cumulativeSteps];
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    final rawSamples = json['samples'] as List<dynamic>;
    final samples = <SensorSample>[];
    for (final raw in rawSamples) {
      try {
        samples.add(SensorSample.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        // Skip unknown sample types
      }
    }

    return Session(
      id: json['id'] as String,
      notes: json['notes'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: json['duration'] as int,
      distance: (json['distance'] as num).toDouble(),
      phase: json['phase'] as String,
      profileId: json['profileId'] as int,
      samples: samples,
    );
  }
}
