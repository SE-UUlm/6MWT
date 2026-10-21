import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

import 'distance_estimator.dart';

/// Initial experimental parameters, not a guarantee of measurement accuracy.
class KalmanGpsConfig {
  KalmanGpsConfig({
    this.maxAccuracy = 20,
    this.maxSpeed = 4,
    this.minPositionSigma = 3,
    this.initialVelocitySigma = 2,
    this.accelerationSigma = 1.5,
    this.innovationThreshold = 9.21,
    this.gapSeconds = 15,
    this.minDistance = 5,
    this.accuracyDistanceFactor = 0.5,
  }) {
    final positive = [
      maxAccuracy,
      maxSpeed,
      minPositionSigma,
      initialVelocitySigma,
      accelerationSigma,
      innovationThreshold,
      gapSeconds,
      minDistance,
    ];
    if (positive.any((v) => !v.isFinite || v <= 0) ||
        !accuracyDistanceFactor.isFinite ||
        accuracyDistanceFactor < 0) {
      throw ArgumentError(
        'Kalman GPS parameters must be finite and positive '
        '(accuracyDistanceFactor may be zero).',
      );
    }
  }

  final double maxAccuracy;
  final double maxSpeed;
  final double minPositionSigma;
  final double initialVelocitySigma;
  final double accelerationSigma;
  final double innovationThreshold;
  final double gapSeconds;
  final double minDistance;
  final double accuracyDistanceFactor;
}

/// Causal, GPS-only comparison estimator. No wall clock, step data, or reference
/// trajectory is used. Predictions never add distance without an accepted fix.
class KalmanGpsDistanceEstimator extends DistanceEstimator {
  KalmanGpsDistanceEstimator({KalmanGpsConfig? config})
    : config = config ?? KalmanGpsConfig();

  final KalmanGpsConfig config;
  String? _source;
  DateTime? _lastSeen;
  _Fix? _origin;
  _Fix? _last;
  _Fix? _pending;
  _State? _state;
  math.Point<double>? _distanceAnchor;
  double _distance = 0;
  double _gapDistance = 0;
  double _gapDuration = 0;
  int _accepted = 0;
  int _gaps = 0;
  int _rejectedConnections = 0;
  final Map<String, int> _rejected = {};

  @override
  double get totalDistance => _distance;

  @override
  Map<String, String> get additionalInfo => {
    'GPS accepted': '$_accepted',
    'GPS rejected': '${_rejected.values.fold(0, (a, b) => a + b)}',
    for (final reason in _rejected.entries)
      'Rejected: ${reason.key}': '${reason.value}',
    'Recovery pending': '${_pending != null}',
    'GPS gaps': '$_gaps',
    'Rejected gap connections': '$_rejectedConnections',
    'Gap duration': '${_gapDuration.toStringAsFixed(1)} s',
    'Gap distance (straight-line estimate)':
        '${_gapDistance.toStringAsFixed(1)} m',
    'GPS source': _source ?? 'None',
    'Max accuracy / speed': '${config.maxAccuracy} m / ${config.maxSpeed} m/s',
    'Position / initial velocity sigma':
        '${config.minPositionSigma} m / ${config.initialVelocitySigma} m/s',
    'Acceleration sigma': '${config.accelerationSigma} m/s²',
    'Innovation threshold': '${config.innovationThreshold}',
    'Gap threshold': '${config.gapSeconds} s',
    'Distance threshold':
        'max(${config.minDistance} m, ${config.accuracyDistanceFactor} × accuracy)',
  };

  @override
  void addSample(SensorSample sample) {
    if (sample.type != SampleType.position) return;
    if (_source != null && sample.sourceId != _source) return;
    if (_lastSeen != null && !sample.timestamp.isAfter(_lastSeen!)) {
      _reject('timestamp');
      return;
    }
    // An invalid sample from an as-yet unselected source must not establish
    // the timestamp baseline for the source that is eventually selected.
    if (_source != null) _lastSeen = sample.timestamp;
    final lat = sample.values[PositionKeys.latitude];
    final lon = sample.values[PositionKeys.longitude];
    final accuracy = sample.values[PositionKeys.accuracy];
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      _reject('coordinates');
      _discardPending();
      return;
    }
    if (accuracy == null ||
        !accuracy.isFinite ||
        accuracy <= 0 ||
        accuracy > config.maxAccuracy) {
      _reject('accuracy');
      _discardPending();
      return;
    }
    final fix = _Fix(lat, lon, accuracy, sample.timestamp);
    _source ??= sample.sourceId;
    _lastSeen = sample.timestamp;
    final last = _last;
    if (last == null) {
      _initialize(fix);
      _accepted++;
      return;
    }
    final dt = fix.secondsSince(last);
    if (dt > config.gapSeconds) {
      _recover(fix);
      return;
    }
    if (!_plausible(last, fix)) {
      _reject('speed');
      return;
    }
    final position = _project(fix);
    final predicted = _state!.predict(dt, config.accelerationSigma);
    final variance = _measurementVariance(fix);
    if (!predicted.isFinite || !variance.isFinite) {
      _reject('numerical');
      return;
    }
    final dx = position.x - predicted.x;
    final dy = position.y - predicted.y;
    final innovationVariance = predicted.pp + variance;
    final nis = (dx * dx + dy * dy) / innovationVariance;
    if (!nis.isFinite || nis > config.innovationThreshold) {
      _reject('innovation');
      return;
    }
    final updated = predicted.update(dx, dy, variance);
    if (!updated.isFinite) {
      _reject('numerical');
      return;
    }
    _state = updated;
    _last = fix;
    _accepted++;
    _book(_state!.position, fix.accuracy);
  }

  double _measurementVariance(_Fix fix) =>
      math.pow(math.max(config.minPositionSigma, fix.accuracy), 2).toDouble();

  bool _plausible(_Fix from, _Fix to) {
    final dt = to.secondsSince(from);
    final meters = Geolocator.distanceBetween(
      from.lat,
      from.lon,
      to.lat,
      to.lon,
    );
    return dt > 0 &&
        meters.isFinite &&
        meters <= config.maxSpeed * dt + from.accuracy + to.accuracy;
  }

  void _initialize(_Fix fix) {
    _origin = fix;
    _last = fix;
    _state = _State(
      0,
      0,
      0,
      0,
      _measurementVariance(fix),
      0,
      config.initialVelocitySigma * config.initialVelocitySigma,
    );
    _distanceAnchor = const math.Point(0.0, 0.0);
  }

  void _recover(_Fix fix) {
    final pending = _pending;
    if (pending == null) {
      _pending = fix;
      return;
    }
    if (!_plausible(pending, fix)) {
      _discardPending();
      _pending = fix;
      return;
    }
    // Confirmation is deliberately independent of the old innovation gate:
    // an initially wrong fix must not permanently lock the estimator out.
    _gaps++;
    _gapDuration += pending.secondsSince(_last!);
    if (_plausible(_last!, pending)) {
      final bridge = _project(pending).distanceTo(_distanceAnchor!);
      _distance += bridge;
      _gapDistance += bridge;
    } else {
      _rejectedConnections++;
    }
    _initialize(pending);
    _accepted += 2;
    _pending = null;
    if (fix.secondsSince(pending) > config.gapSeconds) {
      // Sparse sampling can place both confirmed fixes after separate gaps.
      // Connect both explicitly instead of extrapolating a long Kalman step.
      final bridge = _project(fix).distanceTo(_distanceAnchor!);
      _distance += bridge;
      _gapDistance += bridge;
      _gapDuration += fix.secondsSince(pending);
      _gaps++;
      _initialize(fix);
      return;
    }
    // Both recovery fixes passed the independent quality/speed checks. Use the
    // second measurement to establish motion without applying the stale gate.
    final p = _project(fix);
    final predicted = _state!.predict(
      fix.secondsSince(pending),
      config.accelerationSigma,
    );
    _state = predicted.update(
      p.x - predicted.x,
      p.y - predicted.y,
      _measurementVariance(fix),
    );
    _last = fix;
    _book(_state!.position, fix.accuracy);
  }

  void _book(math.Point<double> position, double accuracy) {
    final meters = position.distanceTo(_distanceAnchor!);
    if (meters >=
        math.max(
          config.minDistance,
          config.accuracyDistanceFactor * accuracy,
        )) {
      _distance += meters;
      _distanceAnchor = position;
    }
  }

  // Local east/north tangent plane on a spherical Earth. Trigonometric longitude
  // differences work across the dateline and at the poles. Rebase on recovery.
  math.Point<double> _project(_Fix fix) {
    const radius = 6371000.0;
    const radians = math.pi / 180;
    final lat = fix.lat * radians;
    final originLat = _origin!.lat * radians;
    final deltaLon = (fix.lon - _origin!.lon) * radians;
    return math.Point(
      radius * math.cos(lat) * math.sin(deltaLon),
      radius *
          (math.cos(originLat) * math.sin(lat) -
              math.sin(originLat) * math.cos(lat) * math.cos(deltaLon)),
    );
  }

  void _reject(String reason) =>
      _rejected.update(reason, (n) => n + 1, ifAbsent: () => 1);

  void _discardPending() {
    if (_pending != null) _reject('unconfirmed recovery');
    _pending = null;
  }

  @override
  void reset() {
    _source = null;
    _lastSeen = null;
    _origin = null;
    _last = null;
    _pending = null;
    _state = null;
    _distanceAnchor = null;
    _distance = 0;
    _gapDistance = 0;
    _gapDuration = 0;
    _accepted = 0;
    _gaps = 0;
    _rejectedConnections = 0;
    _rejected.clear();
  }
}

class _Fix {
  const _Fix(this.lat, this.lon, this.accuracy, this.time);
  final double lat;
  final double lon;
  final double accuracy;
  final DateTime time;
  double secondsSince(_Fix other) =>
      time.difference(other.time).inMicroseconds / 1e6;
}

/// Independent x/vx and y/vy filters share the same isotropic 2×2 covariance.
/// This is algebraically equivalent to the four-state block-diagonal filter.
class _State {
  const _State(this.x, this.y, this.vx, this.vy, this.pp, this.pv, this.vv);
  final double x, y, vx, vy;
  final double pp, pv, vv;
  bool get isFinite =>
      [x, y, vx, vy, pp, pv, vv].every((v) => v.isFinite) && pp >= 0 && vv >= 0;
  math.Point<double> get position => math.Point(x, y);

  _State predict(double dt, double accelerationSigma) {
    final dt2 = dt * dt;
    final q = accelerationSigma * accelerationSigma;
    return _State(
      x + vx * dt,
      y + vy * dt,
      vx,
      vy,
      pp + 2 * dt * pv + dt2 * vv + q * dt2 * dt2 / 4,
      pv + dt * vv + q * dt2 * dt / 2,
      vv + q * dt2,
    );
  }

  _State update(double dx, double dy, double r) {
    final s = pp + r;
    final kp = pp / s;
    final kv = pv / s;
    final a = 1 - kp;
    // Joseph form: (I-KH)P(I-KH)' + KRK', preserving covariance symmetry.
    return _State(
      x + kp * dx,
      y + kp * dy,
      vx + kv * dx,
      vy + kv * dy,
      a * a * pp + kp * kp * r,
      a * (pv - kv * pp) + kp * kv * r,
      vv - 2 * kv * pv + kv * kv * (pp + r),
    );
  }
}
