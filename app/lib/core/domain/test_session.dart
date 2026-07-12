import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../sensors/location_service.dart';
import 'distance_estimator.dart';

enum TestPhase { idle, running, finished, aborted }

// Immutable snapshot of a walk test at one point in time.
class TestSessionState {
  const TestSessionState({
    required this.phase,
    required this.remainingTime,
    this.distanceMeters = 0,
    this.currentPosition,
    this.errorMessage,
  });

  final TestPhase phase;
  final Duration remainingTime;
  final double distanceMeters;
  final Position? currentPosition;
  final String? errorMessage;

  bool get isRunning => phase == TestPhase.running;

  String get formattedRemainingTime {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Runs the walk test (timer + position tracking) independently of any UI, so
// the test survives navigation and can later run in a foreground service.
class TestSession {
  TestSession({
    required this._locationService,
    required this._distanceEstimator,
    this.testDuration = const Duration(minutes: 6),
  }) {
    _state = TestSessionState(phase: TestPhase.idle, remainingTime: testDuration);
  }

  final Duration testDuration;
  final LocationService _locationService;
  final DistanceEstimator _distanceEstimator;

  final StreamController<TestSessionState> _stateController =
      StreamController<TestSessionState>.broadcast();

  late TestSessionState _state;

  StreamSubscription<Position>? _positionSubscription;
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

    final hasPermission = await _locationService.requestLocationPermission();

    if (!hasPermission) {
      _emit(
        TestSessionState(
          phase: TestPhase.idle,
          remainingTime: testDuration,
          errorMessage: 'Location permission denied or GPS disabled',
        ),
      );
      return;
    }

    _cancelTracking();
    _distanceEstimator.reset();

    _emit(TestSessionState(phase: TestPhase.running, remainingTime: testDuration));

    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    _positionSubscription = _locationService.getPositionStream().listen(
      _onPosition,
      onError: _onPositionError,
    );
  }

  void abort() {
    if (!_state.isRunning) {
      return;
    }

    _cancelTracking();

    _emit(
      TestSessionState(
        phase: TestPhase.aborted,
        remainingTime: _state.remainingTime,
        distanceMeters: _state.distanceMeters,
        currentPosition: _state.currentPosition,
      ),
    );
  }

  void reset() {
    _cancelTracking();
    _distanceEstimator.reset();

    _emit(TestSessionState(phase: TestPhase.idle, remainingTime: testDuration));
  }

  void dispose() {
    _cancelTracking();
    _stateController.close();
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
        currentPosition: _state.currentPosition,
      ),
    );
  }

  void _onPosition(Position position) {
    if (!_state.isRunning) {
      return;
    }

    _distanceEstimator.addPosition(position);

    _emit(
      TestSessionState(
        phase: TestPhase.running,
        remainingTime: _state.remainingTime,
        distanceMeters: _distanceEstimator.totalDistance,
        currentPosition: position,
      ),
    );
  }

  void _onPositionError(Object error) {
    _emit(
      TestSessionState(
        phase: _state.phase,
        remainingTime: _state.remainingTime,
        distanceMeters: _state.distanceMeters,
        currentPosition: _state.currentPosition,
        errorMessage: 'Location error: $error',
      ),
    );
  }

  void _finish() {
    _cancelTracking();

    _emit(
      TestSessionState(
        phase: TestPhase.finished,
        remainingTime: Duration.zero,
        distanceMeters: _state.distanceMeters,
        currentPosition: _state.currentPosition,
      ),
    );
  }

  void _cancelTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    _ticker?.cancel();
    _ticker = null;
  }

  void _emit(TestSessionState newState) {
    _state = newState;

    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
