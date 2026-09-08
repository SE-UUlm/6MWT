import 'haversine.dart';
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
  Session({
    required this.id,
    required this.notes,
    required this.startedAt,
    required this.duration,
    required this.distance,
    required this.phase,
    required this.profileId,
    required this.samples,
    this.profile,
    this.referenceSession,
  });

  final String id;
  final String notes;
  final DateTime startedAt;
  final int duration; // seconds
  final double distance; // meters
  final String phase;
  final int profileId;
  final List<SensorSample> samples;
  final Profile? profile;
  final Session? referenceSession;

  // Cached filtered sample lists (lazily computed).
  List<SensorSample>? _positionSamplesCache;
  List<SensorSample>? _stepSamplesCache;

  /// True if a reference recording (reference.json) is attached.
  bool get hasReference => referenceSession != null;

  /// Start time of the session in UTC (based on first GPS timestamp or startedAt).
  DateTime get sessionStartUtc {
    if (positionSamples.isNotEmpty) {
      return positionSamples.first.timestamp.toUtc();
    }
    return startedAt.toUtc();
  }

  /// Calculated end time of the active session in UTC.
  /// Based on the latest sample timestamp of this session (or sessionStartUtc + duration if no samples).
  DateTime get sessionEndUtc {
    DateTime? latest;

    if (positionSamples.isNotEmpty) {
      latest = positionSamples.last.timestamp.toUtc();
    }

    if (stepSamples.isNotEmpty) {
      // Step samples may have local timestamps without timezone indicator,
      // so compute elapsed duration relative to their own stream start.
      final stepDuration =
          stepSamples.last.timestamp.difference(stepSamples.first.timestamp);
      final stepEnd = sessionStartUtc.add(stepDuration);
      if (latest == null || stepEnd.isAfter(latest)) {
        latest = stepEnd;
      }
    }

    if (latest != null) {
      return latest;
    }

    return sessionStartUtc.add(Duration(seconds: duration));
  }

  /// Returns a trimmed copy of [referenceSession] trimmed to this session's
  /// active window [sessionStartUtc, sessionEndUtc], plus at most 1 buffer
  /// sample before the start and 1 buffer sample after the end.
  Session? get trimmedReferenceSession {
    final ref = referenceSession;
    if (ref == null) return null;
    return ref.trimToWindow(
      start: sessionStartUtc,
      end: sessionEndUtc,
    );
  }

  /// Trims this session's samples to [start, end] window, plus at most 1 sample
  /// immediately before start and 1 sample immediately after end for boundary continuity.
  Session trimToWindow({
    required DateTime start,
    required DateTime end,
  }) {
    if (samples.isEmpty) return this;

    final samplesByType = <SampleType, List<SensorSample>>{};
    for (final sample in samples) {
      samplesByType.putIfAbsent(sample.type, () => []).add(sample);
    }

    final trimmedSamples = <SensorSample>[];

    for (final entry in samplesByType.entries) {
      final list = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      int? beforeIdx;
      int? afterIdx;

      for (int i = 0; i < list.length; i++) {
        final t = list[i].timestamp.toUtc();
        if (t.isBefore(start)) {
          beforeIdx = i;
        } else if (t.isAfter(end) && afterIdx == null) {
          afterIdx = i;
          break;
        }
      }

      final startIdx = beforeIdx ?? 0;
      final endIdx = afterIdx ?? (list.length - 1);

      if (startIdx <= endIdx) {
        trimmedSamples.addAll(list.sublist(startIdx, endIdx + 1));
      }
    }

    trimmedSamples.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate trimmed distance
    final posSamples =
        trimmedSamples.where((s) => s.type == SampleType.position).toList();
    double newDistance = distance;
    if (posSamples.length >= 2) {
      final firstDist = posSamples.first.values[PositionKeys.distance];
      final lastDist = posSamples.last.values[PositionKeys.distance];
      if (firstDist != null && lastDist != null) {
        newDistance = (lastDist - firstDist).toDouble();
      } else {
        // Fallback: Haversine sum
        double totalH = 0.0;
        for (int i = 1; i < posSamples.length; i++) {
          final p1 = posSamples[i - 1];
          final p2 = posSamples[i];
          totalH += haversineDistance(
            lat1: p1.values[PositionKeys.latitude]!,
            lon1: p1.values[PositionKeys.longitude]!,
            lat2: p2.values[PositionKeys.latitude]!,
            lon2: p2.values[PositionKeys.longitude]!,
          );
        }
        newDistance = totalH;
      }
    }

    // Calculate trimmed duration
    int newDuration = duration;
    if (trimmedSamples.isNotEmpty) {
      newDuration = trimmedSamples.last.timestamp
          .difference(trimmedSamples.first.timestamp)
          .inSeconds
          .abs();
    }

    return Session(
      id: '${id}_trimmed',
      notes: notes,
      startedAt:
          trimmedSamples.isNotEmpty ? trimmedSamples.first.timestamp : startedAt,
      duration: newDuration,
      distance: newDistance,
      phase: phase,
      profileId: profileId,
      samples: trimmedSamples,
      profile: profile,
    );
  }

  Session copyWith({
    Session? referenceSession,
    Profile? profile,
  }) {
    return Session(
      id: id,
      notes: notes,
      startedAt: startedAt,
      duration: duration,
      distance: distance,
      phase: phase,
      profileId: profileId,
      samples: samples,
      profile: profile ?? this.profile,
      referenceSession: referenceSession ?? this.referenceSession,
    );
  }

  /// All GPS position samples, in order.
  List<SensorSample> get positionSamples =>
      _positionSamplesCache ??=
          samples.where((s) => s.type == SampleType.position).toList();

  /// All step samples that contain cumulative_steps.
  List<SensorSample> get stepSamples =>
      _stepSamplesCache ??= samples
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
    final rawSamples = json['samples'] as List<dynamic>? ?? [];
    final samples = <SensorSample>[];
    for (final raw in rawSamples) {
      try {
        samples.add(SensorSample.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        // Skip unknown sample types
      }
    }

    Profile? profile;
    if (json['profile'] != null && json['profile'] is Map<String, dynamic>) {
      try {
        profile = Profile.fromJson(json['profile'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return Session(
      id: json['id'] as String,
      notes: json['notes'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      phase: json['phase'] as String? ?? 'unknown',
      profileId: (json['profileId'] as num?)?.toInt() ?? 0,
      samples: samples,
      profile: profile,
    );
  }
}
