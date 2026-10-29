import 'dart:async';

import 'package:six_minute_walk_test/core/domain/sample_sink.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';

class FakeSensorSource extends SensorSource {
  FakeSensorSource({this.available = true});

  final bool available;
  final StreamController<SensorSample> controller =
      StreamController<SensorSample>.broadcast();

  bool started = false;
  bool stopped = false;
  int startCalls = 0;

  @override
  String get sourceId => 'fake';

  @override
  Stream<SensorSample> get samples => controller.stream;

  @override
  Future<void> start() async {
    startCalls++;
    if (!available) {
      throw const SensorUnavailableException('sensor unavailable');
    }
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

class InitialSampleFakeSensorSource extends FakeSensorSource {
  InitialSampleFakeSensorSource(this.initialSamples);

  final List<SensorSample> initialSamples;
  int initialSampleCalls = 0;

  @override
  Future<List<SensorSample>> getInitialSamples() async {
    initialSampleCalls++;
    return initialSamples;
  }
}

class RecordingSink implements SampleSink {
  final List<(String, SensorSample)> recorded = [];
  int flushCount = 0;

  @override
  void addSample(String sessionId, SensorSample sample) {
    recorded.add((sessionId, sample));
  }

  @override
  Future<void> flush() async {
    flushCount++;
  }
}
