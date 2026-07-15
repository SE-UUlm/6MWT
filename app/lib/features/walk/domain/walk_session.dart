import 'dart:async';
import 'dart:math';

import 'package:six_minute_walk_test/core/domain/sample_sink.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';

import 'distance_estimator.dart';

enum WalkPhase { idle, running, finished, aborted }

// Immutable snapshot of a walk test at one point in time.
class WalkSessionState {
  const WalkSessionState({
    required this.phase,
    required this.remainingTime,
    this.distanceMeters = 0,
    this.lastSamples = const {},
    this.errorMessage,
    this.sessionId,
    this.startedAt,
  });

  final WalkPhase phase;
  final Duration remainingTime;
  final double distanceMeters;

  // Latest sample per sample type, for display purposes.
  final Map<SampleType, SensorSample> lastSamples;

  final String? errorMessage;

  // Set while a test is running or after it ended; links the recorded raw
  // samples and the stored result to this run.
  final String? sessionId;
  final DateTime? startedAt;

  bool get isRunning => phase == WalkPhase.running;

  String get formattedRemainingTime {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Runs the walk test (timer + position tracking) independently of any UI, so
// the test survives navigation and can later run in a foreground service.
class WalkSession {
  WalkSession({
    required this._sources,
    required this._distanceEstimator,
    this._sampleSink,
    this._optionalSources = const [],
    this.walkDuration = const Duration(minutes: 6),
  }) {
    _state = WalkSessionState(
      phase: WalkPhase.idle,
      remainingTime: walkDuration,
    );
  }

  final Duration walkDuration;

  // The test cannot start when one of these is unavailable (e.g. GPS).
  final List<SensorSource> _sources;

  // Nice-to-have sources (steps, health data): recorded when available,
  // silently skipped when not.
  final List<SensorSource> _optionalSources;

  final DistanceEstimator _distanceEstimator;
  final SampleSink? _sampleSink;

  final StreamController<WalkSessionState> _stateController =
      StreamController<WalkSessionState>.broadcast();

  late WalkSessionState _state;

  final List<StreamSubscription<SensorSample>> _sampleSubscriptions = [];
  final List<SensorSource> _activeSources = [];
  Timer? _ticker;

  WalkSessionState get state => _state;

  // Emits the current state immediately, then every subsequent change.
  Stream<WalkSessionState> get states async* {
    yield _state;
    yield* _stateController.stream;
  }

  Future<void> start() async {
    if (_state.isRunning) {
      return;
    }

    final startedAt = DateTime.now();
    final sessionId = _generateSessionId();

    _distanceEstimator.reset();

    _emit(
      WalkSessionState(
        phase: WalkPhase.running,
        remainingTime: walkDuration,
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
        WalkSessionState(
          phase: WalkPhase.idle,
          remainingTime: walkDuration,
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
        print("Cannot start source ${source.sourceId}");
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
      WalkSessionState(
        phase: WalkPhase.aborted,
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

    _emit(WalkSessionState(phase: WalkPhase.idle, remainingTime: walkDuration));
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
      WalkSessionState(
        phase: WalkPhase.running,
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
      WalkSessionState(
        phase: WalkPhase.running,
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
      WalkSessionState(
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
      WalkSessionState(
        phase: WalkPhase.finished,
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

  void _emit(WalkSessionState newState) {
    _state = newState;

    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}

String _generateSessionId([int bytes = 16]) {
  final random = Random.secure();
  return [
    for (var i = 0; i < bytes; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
