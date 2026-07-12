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
    this.lastSamples = const {},
    this.errorMessage,
    this.sessionId,
    this.startedAt,
  });

  final TestPhase phase;
  final Duration remainingTime;
  final double distanceMeters;

  // Latest sample per sample type, for display purposes.
  final Map<String, SensorSample> lastSamples;

  final String? errorMessage;

  // Set while a test is running or after it ended; links the recorded raw
  // samples and the stored result to this run.
  final String? sessionId;
  final DateTime? startedAt;

  bool get isRunning => phase == TestPhase.running;

  SensorSample? get lastPosition => lastSamples[SampleTypes.position];

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
    this._optionalSources = const [],
    this._sampleSink,
    this.testDuration = const Duration(minutes: 6),
  }) {
    _state = TestSessionState(phase: TestPhase.idle, remainingTime: testDuration);
  }

  final Duration testDuration;

  // The test cannot start when one of these is unavailable (e.g. GPS).
  final List<SensorSource> _sources;

  // Nice-to-have sources (steps, health data): recorded when available,
  // silently skipped when not.
  final List<SensorSource> _optionalSources;

  final DistanceEstimator _distanceEstimator;
  final SampleSink? _sampleSink;

  final StreamController<TestSessionState> _stateController =
      StreamController<TestSessionState>.broadcast();

  late TestSessionState _state;

  final List<StreamSubscription<SensorSample>> _sampleSubscriptions = [];
  final List<SensorSource> _activeSources = [];
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

    for (final source in [..._sources, ..._optionalSources]) {
      _sampleSubscriptions.add(
        source.samples.listen(_onSample, onError: _onSampleError),
      );
    }

    try {
      for (final source in _sources) {
        await source.start();
        _activeSources.add(source);
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

    for (final source in _optionalSources) {
      try {
        await source.start();
        _activeSources.add(source);
      } on Exception {
        // Optional sources may be missing (no wearable, no permission,
        // unsupported platform) — the walk test itself is unaffected.
      }
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
        lastSamples: _state.lastSamples,
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
        lastSamples: _state.lastSamples,
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
        lastSamples: {..._state.lastSamples, sample.type: sample},
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
        lastSamples: _state.lastSamples,
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
        lastSamples: _state.lastSamples,
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

    for (final source in _activeSources) {
      try {
        await source.stop();
      } on Exception {
        // Stopping one source must not prevent stopping the others.
      }
    }
    _activeSources.clear();

    await _sampleSink?.flush();
  }

  void _emit(TestSessionState newState) {
    _state = newState;

    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
