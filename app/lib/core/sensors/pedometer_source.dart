import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/sensor_sample.dart';
import '../../app/log.dart';
import 'sensor_source.dart';

final _log = appLogger('PedometerSource');

// Cumulative counts from the phone's step sensor are recorded without rebasing;
// estimators handle their baseline and counter resets.
// Pedometer 4.2.0 timestamps events when constructing the Dart objects, not when
// individual steps occur. Converting to UTC preserves that event time basis.
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
      _log.w('Activity recognition permission not granted: ${status.name}');
      throw const SensorUnavailableException(
        'Activity recognition permission denied',
      );
    }

    runZonedGuarded(
      // Pedometer 4.2.0's Android _androidStream listens internally without an
      // onError handler. Those errors can bypass our status-stream handler and
      // reach this zone instead. See wiki/Development.md for the update check.
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
            _log.w('Step count stream error', error: err);
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
          onError: (Object err) {
            _log.w('Pedestrian status stream error', error: err);
            _controller.addError(err);
          },
        );
        _log.i('Pedometer streams started');
      },
      (error, stack) {
        // Log errors escaping the plugin's internal listener. Unlike errors
        // received by our stream handlers, these are not forwarded to samples.
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
