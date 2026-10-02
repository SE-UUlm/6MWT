import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/sensor_sample.dart';
import '../../app/log.dart';
import 'sensor_source.dart';

final _log = appLogger('PedometerSource');

// Step counts from the phone's built-in step sensor. The platform delivers
// counts cumulative since device boot; they are recorded as-is.
class PedometerSource implements SensorSource {
  static const id = 'pedometer';

  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  SensorSample? _latestStepCountSample;
  SensorSample? _latestPedestrianStatusSample;

  @override
  String get sourceId => id;

  @override
  Stream<SensorSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    _latestStepCountSample = null;
    _latestPedestrianStatusSample = null;

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
      // Not sure why this is needed but otherwise errors from the Pedometer streams are unhandled exceptions, even though they have working onError handlers
      () {
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          (stepCount) {
            final sample = SensorSample(
              timestamp: stepCount.timeStamp.toUtc(),
              sourceId: sourceId,
              type: SampleType.steps,
              values: {StepKeys.cumulativeSteps: stepCount.steps.toDouble()},
            );
            _latestStepCountSample = sample;
            _controller.add(sample);
          },
          onError: (err) {
            _controller.addError(err);
          },
        );

        _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
          (pedestrianStatus) {
            final sample = SensorSample(
              timestamp: pedestrianStatus.timeStamp.toUtc(),
              sourceId: sourceId,
              type: SampleType.steps,
              values: {
                StepKeys.pedestrianStatus: pedestrianStatus.status == "walking"
                    ? 1 // walking
                    : 0, // stopped
              },
            );
            _latestPedestrianStatusSample = sample;
            _controller.add(sample);
          },
          onError: _controller.addError,
        );
      },
      (error, stack) {
        // Really only needed so the debugger is not paused every time
        _log.w(
          'Exception caught in Pedometer',
          error: error,
          stackTrace: stack,
        );
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

  @override
  Future<List<SensorSample>> getInitialSamples() async {
    return [?_latestPedestrianStatusSample, ?_latestStepCountSample];
  }
}
