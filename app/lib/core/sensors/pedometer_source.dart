import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/sensor_sample.dart';
import 'sensor_source.dart';

// Step counts from the phone's built-in step sensor. The platform delivers
// counts cumulative since device boot; they are recorded as-is.
class PedometerSource implements SensorSource {
  static const id = 'pedometer';

  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  @override
  String get sourceId => id;

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    Permission permission = Platform.isIOS
        ? Permission.sensors
        : Permission.activityRecognition; // Android

    final status = await permission.request();

    if (!status.isGranted) {
      throw const SensorUnavailableException(
        'Activity recognition permission denied',
      );
    }

    runZonedGuarded(
      // Not sure why this is neede but otherwise errors from the Pedometer streams are unhandled exceptions, even though they have working onError handlers
      () {
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          (stepCount) => _controller.add(
            SensorSample(
              timestamp: stepCount.timeStamp,
              sourceId: sourceId,
              type: SampleType.steps,
              values: {StepKeys.cumulativeSteps: stepCount.steps.toDouble()},
            ),
          ),
          onError: (err) {
            print("On Error ${_controller.hasListener}");
            _controller.addError(err);
          },
        );

        _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
          (pedestrianStatus) => _controller.add(
            SensorSample(
              timestamp: pedestrianStatus.timeStamp,
              sourceId: sourceId,
              type: SampleType.steps,
              values: {
                StepKeys.pedestrianStatus: pedestrianStatus.status == "walking"
                    ? 1 // walking
                    : 0, // stopped
              },
            ),
          ),
          onError: _controller.addError,
        );
      },
      (error, stack) {
        // Really only needed so the debugger is not paused every time
        print("Exception caught in Pedometer: $error");
      },
    );
  }

  @override
  Future<void> stop() async {
    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;

    await _pedestrianStatusSubscription?.cancel();
    _pedestrianStatusSubscription = null;
  }
}
