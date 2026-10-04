import 'dart:async';
import 'dart:math';

import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/domain/sample_sink.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/sensors/sensor_source.dart';

import 'distance_estimator.dart';
import 'estimator_comparison.dart';

final _log = appLogger('WalkSession');

// Immutable snapshot of a walk test at one point in time.
class WalkSessionState {
  const WalkSessionState({
    required this.phase,
    required this.remainingTime,
    this.distance = 0, // In meters
    this.comparisons = const [],
    this.lastSamples = const {},
    this.errorMessage,
    this.sessionId,
    this.startedAt,
  });

  final WalkPhase phase;
  final Duration remainingTime;
  final double distance;
  final List<EstimatorComparison> comparisons;

  // Latest sample per sample type, for display purposes.
  final Map<SampleType, SensorSample> lastSamples;

  final String? errorMessage;

  // Set while a test is running or after it ended; links the recorded raw
  // samples and the stored result to this run.
  final String? sessionId;

  /// Session start in UTC. Convert with toLocal() when displaying a wall-clock time.
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
    List<NamedDistanceEstimator> comparisonEstimators = const [],
    this.walkDuration = const Duration(minutes: 6),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _comparisonEstimators = List.unmodifiable(comparisonEstimators) {
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
  final List<NamedDistanceEstimator> _comparisonEstimators;
  final Map<int, String> _comparisonErrors = {};
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
  Future<void>? _warmUpFuture;

  int? profileId;

  WalkSessionState get state => _state;

  // Emits the current state immediately, then every subsequent change.
  Stream<WalkSessionState> get states async* {
    yield _state;
    yield* _stateController.stream;
  }

  /// Starts the sensors before a test begins so that, in particular, GPS has
  /// time to acquire an accurate position. Warm-up samples are deliberately
  /// not observed or persisted; recording starts only with [start].
  Future<void> warmUp() {
    if (_state.isRunning || _warmUpFuture != null) {
      return _warmUpFuture ?? Future.value();
    }

    _log.i("Warming up sensors");

    final future = _warmUp();
    _warmUpFuture = future;
    future.whenComplete(() {
      if (identical(_warmUpFuture, future)) {
        _warmUpFuture = null;
      }
    });
    return future;
  }

  Future<void> _warmUp() async {
    try {
      await _startSources();
    } on Exception catch (exception) {
      await _stopSources();
      _emit(
        WalkSessionState(
          phase: WalkPhase.idle,
          remainingTime: walkDuration,
          errorMessage: exception.toString(),
        ),
      );
    }
  }

  /// Stops sensors that are only active for warm-up. A running test remains
  /// active when its screen is replaced or temporarily covered.
  Future<void> stopWarmUp() async {
    if (_state.isRunning) {
      return;
    }

    _log.i("Stopping warm up");

    final warmUpFuture = _warmUpFuture;
    if (warmUpFuture != null) {
      await warmUpFuture;
    }
    await _stopSources();
  }

  Future<void> start() async {
    if (_state.isRunning) {
      return;
    }

    final warmUpFuture = _warmUpFuture;
    if (warmUpFuture != null) {
      await warmUpFuture;
    }

    if (_state.isRunning) {
      return;
    }

    final startedAt = _now().toUtc();
    final sessionId = _generateSessionId();

    _distanceEstimator.reset();
    _resetComparisons();

    _emit(
      WalkSessionState(
        phase: WalkPhase.running,
        remainingTime: walkDuration,
        sessionId: sessionId,
        startedAt: startedAt,
        comparisons: _snapshotComparisons(),
      ),
    );

    try {
      await _startSources();
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

    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    await _recordInitialSamples();

    // The session may have been aborted while an initial sample was awaited.
    if (!_state.isRunning || _state.sessionId != sessionId) {
      return;
    }

    for (final source in [..._sources, ..._optionalSources]) {
      _sampleSubscriptions.add(
        source.samples.listen(_onSample, onError: _onSampleError),
      );
    }
  }

  Future<void> abort() async {
    if (!_state.isRunning) {
      return;
    }

    final remaining = _remainingTimeAt(_now());
    if (remaining == Duration.zero) {
      await _finish();
      return;
    }

    await _stopTracking();

    _emit(
      WalkSessionState(
        phase: WalkPhase.aborted,
        comparisons: _state.comparisons,
        remainingTime: remaining,
        distance: _state.distance,
        lastSamples: _state.lastSamples,
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  Future<void> reset() async {
    if (_state.isRunning ||
        _activeSources.isNotEmpty ||
        _sampleSubscriptions.isNotEmpty) {
      await _stopTracking();
    }
    _distanceEstimator.reset();
    _resetComparisons();

    _emit(WalkSessionState(phase: WalkPhase.idle, remainingTime: walkDuration));
  }

  Future<void> dispose() async {
    await _stopTracking();
    await _stateController.close();
  }

  /// Reconciles the displayed state with the wall clock after backgrounding.
  ///
  /// Dart timers may be paused while the app is in the background. The test
  /// deadline itself is absolute, so recalculating it when the app resumes
  /// immediately restores the correct countdown or finishes the test.
  void synchronizeWithClock() {
    if (!_state.isRunning) {
      return;
    }

    _updateForCurrentTime();
  }

  void _onTick(Timer _) => _updateForCurrentTime();

  void _updateForCurrentTime() {
    final remaining = _remainingTimeAt(_now());

    if (remaining <= Duration.zero) {
      unawaited(_finish());
      return;
    }

    _emit(
      WalkSessionState(
        phase: WalkPhase.running,
        remainingTime: remaining,
        comparisons: _state.comparisons,
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
      unawaited(_finish());
      return;
    }

    _sampleSink?.addSample(sessionId, sample);
    _distanceEstimator.addSample(sample);
    for (var i = 0; i < _comparisonEstimators.length; i++) {
      _runComparison(
        i,
        () => _comparisonEstimators[i].estimator.addSample(sample),
      );
    }

    _emit(
      WalkSessionState(
        phase: WalkPhase.running,
        remainingTime: remaining,
        distance: _distanceEstimator.totalDistance,
        comparisons: _snapshotComparisons(),
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
      unawaited(_finish());
      return;
    }

    _emit(
      WalkSessionState(
        phase: _state.phase,
        comparisons: _state.comparisons,
        remainingTime: remaining,
        distance: _state.distance,
        lastSamples: _state.lastSamples,
        errorMessage: 'Sensor error: $error',
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );
  }

  Future<void> _finish() async {
    if (!_state.isRunning) {
      return;
    }

    final stopTracking = _stopTracking();

    _emit(
      WalkSessionState(
        phase: WalkPhase.finished,
        comparisons: _state.comparisons,
        remainingTime: Duration.zero,
        distance: _state.distance,
        lastSamples: _state.lastSamples,
        sessionId: _state.sessionId,
        startedAt: _state.startedAt,
      ),
    );

    await stopTracking;
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

    await _stopSources();

    await _sampleSink?.flush();
  }

  Future<void> _startSources() async {
    for (final source in _sources) {
      if (_activeSources.contains(source)) {
        continue;
      }

      await source.start();
      _activeSources.add(source);
    }

    for (final source in _optionalSources) {
      if (_activeSources.contains(source)) {
        continue;
      }

      try {
        await source.start();
        _activeSources.add(source);
      } on Exception catch (e) {
        _log.w('Cannot start optional source ${source.sourceId}', error: e);
        // Optional sources may be missing (no wearable, no permission,
        // unsupported platform) — the walk test itself is unaffected.
      }
    }
  }

  Future<void> _recordInitialSamples() async {
    // A snapshot keeps iteration stable if the session is aborted while an
    // individual sensor request is awaiting its result.
    final activeSources = List<SensorSource>.of(_activeSources);
    for (final source in activeSources) {
      try {
        final initialSamples = await source.getInitialSamples();
        for (final sample in initialSamples) {
          _onSample(sample);
        }
      } on Exception catch (exception) {
        // The live stream remains authoritative. Failure to obtain this extra
        // initial value must not abort an otherwise running walk test.
        _log.w(
          'Cannot get initial samples from ${source.sourceId}',
          error: exception,
        );
      }
    }
  }

  Future<void> _stopSources() async {
    // Take ownership of the current sources before awaiting their asynchronous
    // stop calls. A second stop request then sees an empty list and is a no-op.
    final sourcesToStop = List<SensorSource>.of(_activeSources);
    _activeSources.clear();

    for (final source in sourcesToStop) {
      try {
        await source.stop();
      } on Exception {
        // Stopping one source must not prevent stopping the others.
      }
    }
  }

  void _runComparison(int index, void Function() action) {
    if (_comparisonErrors.containsKey(index)) return;
    try {
      action();
    } catch (error, stackTrace) {
      _comparisonErrors[index] = error.toString();
      _log.w(
        'Comparison estimator failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _resetComparisons() {
    _comparisonErrors.clear();
    for (var i = 0; i < _comparisonEstimators.length; i++) {
      _runComparison(i, _comparisonEstimators[i].estimator.reset);
    }
  }

  List<EstimatorComparison> _snapshotComparisons() {
    return List.unmodifiable([
      for (var i = 0; i < _comparisonEstimators.length; i++)
        _snapshotComparison(i),
    ]);
  }

  EstimatorComparison _snapshotComparison(int index) {
    final entry = _comparisonEstimators[index];
    EstimatorComparison? result;
    _runComparison(index, () {
      final distance = entry.estimator.totalDistance;
      if (!distance.isFinite || distance < 0) {
        throw StateError('Invalid comparison distance');
      }
      result = EstimatorComparison(
        name: entry.name,
        distance: distance,
        additionalInfo: entry.estimator.additionalInfo,
      );
    });
    return result ??
        EstimatorComparison(
          name: entry.name,
          distance: 0,
          error: _comparisonErrors[index],
        );
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
