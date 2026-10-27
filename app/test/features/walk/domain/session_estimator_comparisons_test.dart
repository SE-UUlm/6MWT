import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';

import '../../../helpers/fake_sensors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (heightCm, gender, expected) in <(num?, String?, double)>[
    (180, 'male', 7.47),
    (180, 'female', 7.434),
    (180, 'other', 7.452),
    (180, null, 7.452),
    (null, null, 7),
    (0, 'female', 7),
  ]) {
    test(
      'history matches live distance for height=$heightCm, gender=$gender',
      () async {
        final start = DateTime.utc(2026);
        final samples = [
          SensorSample(
            timestamp: start,
            type: SampleType.steps,
            sourceId: PedometerSource.id,
            values: {StepKeys.cumulativeSteps: 1000},
          ),
          SensorSample(
            timestamp: start.add(const Duration(seconds: 10)),
            type: SampleType.steps,
            sourceId: PedometerSource.id,
            values: {StepKeys.cumulativeSteps: 1010},
          ),
        ];
        final source = InitialSampleFakeSensorSource(samples);
        addTearDown(source.controller.close);
        final live = WalkSession(
          sources: [source],
          distanceEstimator: createPrimaryDistanceEstimator(),
          now: () => start,
        );
        addTearDown(live.dispose);
        if (heightCm != null) {
          live.setProfile(id: 1, heightCm: heightCm, gender: gender);
        }
        await live.start();
        expect(live.state.distance, closeTo(expected, 1e-6));
        await live.abort();

        final comparisons = await compute(
          computeEstimatorComparisons,
          EstimatorComparisonInput(
            samples: samples,
            heightCm: heightCm,
            gender: gender,
          ),
        );
        final main = comparisons.first;
        expect(main.error, isNull);
        expect(main.distance, closeTo(live.state.distance, 1e-6));
        expect(main.additionalInfo['Calibration'], 'Default');
        // The fixed step comparison keeps its own configured length.
        expect(comparisons.last.distance, closeTo(7.5, 1e-6));
      },
    );
  }
}
