import 'dart:async';
import 'dart:math';

import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/domain/sample_sink.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';

import 'distance_estimator.dart';

final _log = appLogger('WalkSession');

// Immutable snapshot of a walk test at one point in time.
class WalkSessionState {
  const WalkSessionState({
    required this.phase,
    required this.remainingTime,
    this.distance = 0, // In meters
    this.lastSamples = const {},
    this.errorMessage,
    this.sessionId,
    this.startedAt,
  });

  final WalkPhase phase;
  final Duration remainingTime;
  final double distance;

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
// the test survives navigation and can continue while the app is in the background
// or the screen is locked.
class WalkSession {
  WalkSession({
    required this._sources,
    required this._distanceEstimator,
    this._sampleSink,
    this._optionalSources = const [],
    this.walkDuration = const Duration(minutes: 6),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
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

  // Provides the current time for deadline calculations and can be replaced
  // with a controlled clock in tests.
  final DateTime Function() _now;

  final StreamController<WalkSessionState> _stateController =
      StreamController<WalkSessionState>.broadcast();

  late WalkSessionState _state;

  final List<StreamSubscription<SensorSample>> _sampleSubscriptions = [];
  final List<SensorSource> _activeSources = [];
  Timer? _ticker;

  int? profileId;

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

    final startedAt = _now();
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
      } on Exception catch (e) {
        _log.w('Cannot start optional source ${source.sourceId}', error: e);
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

    final remaining = _remainingTimeAt(_now());
    if (remaining == Duration.zero) {
      _finish();
      return;
    }

    await _stopTracking();

    _emit(
      WalkSessionState(
        phase: WalkPhase.aborted,
        remainingTime: remaining,
        distance: _state.distance,
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

  void _onTick(Timer _) {
    final remaining = _remainingTimeAt(_now());

    if (remaining <= Duration.zero) {
      _finish();
      return;
    }

    _emit(
      WalkSessionState(
        phase: WalkPhase.running,
        remainingTime: remaining,
        distance: _state.distance,
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

    final remaining = _remainingTimeAt(_now());
    if (remaining == Duration.zero) {
      _finish();
      return;
    }

    _sampleSink?.addSample(sessionId, sample);
    _distanceEstimator.addSample(sample);

    _emit(
      WalkSessionState(
        phase: WalkPhase.running,
        remainingTime: remaining,
        distance: _distanceEstimator.totalDistance,
        lastSamples: {..._state.lastSamples, sample.type: sample},
        sessionId: sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  void _onSampleError(Object error) {
    _log.w('Sample error', error: error);

    final remaining = _remainingTimeAt(_now());
    if (_state.isRunning && remaining == Duration.zero) {
      _finish();
      return;
    }

    _emit(
      WalkSessionState(
        phase: _state.phase,
        remainingTime: remaining,
        distance: _state.distance,
        lastSamples: _state.lastSamples,
        errorMessage: 'Sensor error: $error',
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  void _finish() {
    if (!_state.isRunning) {
      return;
    }

    unawaited(_stopTracking());

    _emit(
      WalkSessionState(
        phase: WalkPhase.finished,
        remainingTime: Duration.zero,
        distance: _state.distance,
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

  // Calculates the remaining time until the walk test deadline based on the
  // elapsed time since the session started.
  Duration _remainingTimeAt(DateTime now) {
    final startedAt = _state.startedAt;
    if (startedAt == null) {
      return walkDuration;
    }

    final elapsed = now.difference(startedAt);
    if (elapsed <= Duration.zero) {
      return walkDuration;
    }

    if (elapsed >= walkDuration) {
      return Duration.zero;
    }

    final remaining = walkDuration - elapsed;
    final hasPartialSecond =
        remaining.inMicroseconds.remainder(Duration.microsecondsPerSecond) != 0;

    // State and persistence are second-based. Rounding up keeps the displayed
    // value stable until the next whole second without changing the exact
    // deadline check above.
    return Duration(seconds: remaining.inSeconds + (hasPartialSecond ? 1 : 0));
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
