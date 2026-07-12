import 'dart:async';

import '../sensors/sensor_source.dart';
import 'distance_estimator.dart';
import 'sample_sink.dart';
import 'sensor_sample.dart';

enum TestPhase { idle, running, finished, aborted }

// Immutable snapshot of a walk test at one point in time.
class TestSessionState {
  const TestSessionState({
    required this.phase,
    required this.remainingTime,
    this.distanceMeters = 0,
    this.lastPosition,
    this.errorMessage,
    this.sessionId,
    this.startedAt,
  });

  final TestPhase phase;
  final Duration remainingTime;
  final double distanceMeters;

  // Latest position sample, for display purposes.
  final SensorSample? lastPosition;

  final String? errorMessage;

  // Set while a test is running or after it ended; links the recorded raw
  // samples and the stored result to this run.
  final String? sessionId;
  final DateTime? startedAt;

  bool get isRunning => phase == TestPhase.running;

  String get formattedRemainingTime {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Runs the walk test (timer + sensor tracking) independently of any UI, so
// the test survives navigation and keeps running in the background.
class TestSession {
  TestSession({
    required this._sources,
    required this._distanceEstimator,
    this._sampleSink,
    this.testDuration = const Duration(minutes: 6),
  }) {
    _state = TestSessionState(phase: TestPhase.idle, remainingTime: testDuration);
  }

  final Duration testDuration;
  final List<SensorSource> _sources;
  final DistanceEstimator _distanceEstimator;
  final SampleSink? _sampleSink;

  final StreamController<TestSessionState> _stateController =
      StreamController<TestSessionState>.broadcast();

  late TestSessionState _state;

  final List<StreamSubscription<SensorSample>> _sampleSubscriptions = [];
  Timer? _ticker;

  TestSessionState get state => _state;

  // Emits the current state immediately, then every subsequent change.
  Stream<TestSessionState> get states async* {
    yield _state;
    yield* _stateController.stream;
  }

  Future<void> start() async {
    if (_state.isRunning) {
      return;
    }

    final startedAt = DateTime.now();
    final sessionId = startedAt.millisecondsSinceEpoch.toString();

    _distanceEstimator.reset();

    _emit(
      TestSessionState(
        phase: TestPhase.running,
        remainingTime: testDuration,
        sessionId: sessionId,
        startedAt: startedAt,
      ),
    );

    for (final source in _sources) {
      _sampleSubscriptions.add(
        source.samples.listen(_onSample, onError: _onSampleError),
      );
    }

    try {
      for (final source in _sources) {
        await source.start();
      }
    } on Exception catch (exception) {
      await _stopTracking();

      _emit(
        TestSessionState(
          phase: TestPhase.idle,
          remainingTime: testDuration,
          errorMessage: exception.toString(),
        ),
      );
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  Future<void> abort() async {
    if (!_state.isRunning) {
      return;
    }

    await _stopTracking();

    _emit(
      TestSessionState(
        phase: TestPhase.aborted,
        remainingTime: _state.remainingTime,
        distanceMeters: _state.distanceMeters,
        lastPosition: _state.lastPosition,
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  Future<void> reset() async {
    await _stopTracking();
    _distanceEstimator.reset();

    _emit(TestSessionState(phase: TestPhase.idle, remainingTime: testDuration));
  }

  Future<void> dispose() async {
    await _stopTracking();
    await _stateController.close();
  }

  void _onTick(Timer timer) {
    final remaining = _state.remainingTime - const Duration(seconds: 1);

    if (remaining <= Duration.zero) {
      _finish();
      return;
    }

    _emit(
      TestSessionState(
        phase: TestPhase.running,
        remainingTime: remaining,
        distanceMeters: _state.distanceMeters,
        lastPosition: _state.lastPosition,
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  void _onSample(SensorSample sample) {
    final sessionId = _state.sessionId;

    if (!_state.isRunning || sessionId == null) {
      return;
    }

    _sampleSink?.addSample(sessionId, sample);
    _distanceEstimator.addSample(sample);

    _emit(
      TestSessionState(
        phase: TestPhase.running,
        remainingTime: _state.remainingTime,
        distanceMeters: _distanceEstimator.totalDistance,
        lastPosition: sample.type == SampleTypes.position
            ? sample
            : _state.lastPosition,
        sessionId: sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  void _onSampleError(Object error) {
    _emit(
      TestSessionState(
        phase: _state.phase,
        remainingTime: _state.remainingTime,
        distanceMeters: _state.distanceMeters,
        lastPosition: _state.lastPosition,
        errorMessage: 'Sensor error: $error',
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  void _finish() {
    unawaited(_stopTracking());

    _emit(
      TestSessionState(
        phase: TestPhase.finished,
        remainingTime: Duration.zero,
        distanceMeters: _state.distanceMeters,
        lastPosition: _state.lastPosition,
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  Future<void> _stopTracking() async {
    _ticker?.cancel();
    _ticker = null;

    // Not awaited: cancel() futures of broadcast subscriptions are bound to
    // the root zone and never complete under fake_async; unsubscribing takes
    // effect synchronously anyway.
    for (final subscription in _sampleSubscriptions) {
      unawaited(subscription.cancel());
    }
    _sampleSubscriptions.clear();

    for (final source in _sources) {
      try {
        await source.stop();
      } on Exception {
        // Stopping a source that never started must not mask the real error.
      }
    }
  }

  void _emit(TestSessionState newState) {
    _state = newState;

    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
