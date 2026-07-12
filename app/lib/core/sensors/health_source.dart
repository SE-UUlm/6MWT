import 'dart:async';

import 'package:health/health.dart';

import '../domain/sensor_sample.dart';
import 'sensor_source.dart';

// Heart rate and SpO2 from HealthKit (iOS) / Health Connect (Android).
// Wearables that sync into these stores (including Gadgetbridge exports)
// arrive here without any device-specific code.
//
// The health APIs are query-based, not streaming, so this source polls: every
// [pollInterval] it reads the data points written since the previous poll.
class HealthSource implements SensorSource {
  HealthSource({this.pollInterval = const Duration(seconds: 10)});

  static const sourceId = 'health';

  static const _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
  ];

  final Duration pollInterval;

  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();

  Timer? _pollTimer;
  DateTime? _lastPollEnd;

  @override
  String get id => sourceId;

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    final health = Health();

    try {
      await health.configure();

      final authorized = await health.requestAuthorization(_types);

      if (!authorized) {
        throw const SensorUnavailableException(
          'Health data access not granted',
        );
      }
    } on SensorUnavailableException {
      rethrow;
    } catch (error) {
      // Health Connect not installed, HealthKit unavailable, unsupported
      // platform, ... — all mean the same thing to consumers.
      throw SensorUnavailableException('Health data unavailable: $error');
    }

    _lastPollEnd = DateTime.now();
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll(health));
  }

  @override
  Future<void> stop() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastPollEnd = null;
  }

  Future<void> _poll(Health health) async {
    final start = _lastPollEnd;

    if (start == null) {
      return;
    }

    final end = DateTime.now();
    _lastPollEnd = end;

    try {
      final points = await health.getHealthDataFromTypes(
        types: _types,
        startTime: start,
        endTime: end,
      );

      for (final point in points) {
        final value = point.value;

        if (value is! NumericHealthValue) {
          continue;
        }

        final sample = switch (point.type) {
          HealthDataType.HEART_RATE => SensorSample(
            timestamp: point.dateFrom,
            sensorId: sourceId,
            type: SampleTypes.heartRate,
            values: {VitalKeys.heartRateBpm: value.numericValue.toDouble()},
          ),
          HealthDataType.BLOOD_OXYGEN => SensorSample(
            timestamp: point.dateFrom,
            sensorId: sourceId,
            type: SampleTypes.spo2,
            values: {VitalKeys.spo2Percent: value.numericValue.toDouble()},
          ),
          _ => null,
        };

        if (sample != null) {
          _controller.add(sample);
        }
      }
    } catch (_) {
      // A failed poll (store busy, transient error) is not fatal; the next
      // poll covers the missed interval via _lastPollEnd.
      _lastPollEnd = start;
    }
  }
}
