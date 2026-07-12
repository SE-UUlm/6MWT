import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/sensor_sample.dart';
import 'sensor_source.dart';

// Step counts from the phone's built-in step sensor. The platform delivers
// counts cumulative since device boot; they are recorded as-is.
class PedometerSource implements SensorSource {
  static const sourceId = 'pedometer';

  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();

  StreamSubscription<StepCount>? _subscription;

  @override
  String get id => sourceId;

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();

      if (!status.isGranted) {
        throw const SensorUnavailableException(
          'Activity recognition permission denied',
        );
      }
    }

    _subscription = Pedometer.stepCountStream.listen(
      (stepCount) => _controller.add(
        SensorSample(
          timestamp: stepCount.timeStamp,
          sensorId: sourceId,
          type: SampleTypes.steps,
          values: {StepKeys.cumulativeSteps: stepCount.steps.toDouble()},
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
