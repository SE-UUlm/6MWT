import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../domain/sensor_sample.dart';
import 'sensor_source.dart';

// Raw accelerometer data (including gravity), sampled at ~50 Hz. Recorded
// purely for offline algorithm development (step/gait analysis).
class AccelerometerSource implements SensorSource {
  static const sourceId = 'accelerometer';

  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();

  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  String get id => sourceId;

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    _subscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          (event) => _controller.add(
            SensorSample(
              timestamp: event.timestamp,
              sensorId: sourceId,
              type: SampleTypes.accelerometer,
              values: {
                AccelerometerKeys.x: event.x,
                AccelerometerKeys.y: event.y,
                AccelerometerKeys.z: event.z,
              },
            ),
          ),
          onError: _controller.addError,
        );
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
