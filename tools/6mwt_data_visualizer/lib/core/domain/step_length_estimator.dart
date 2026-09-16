import 'dart:math' as math;

import 'haversine.dart';
import 'sensor_sample.dart';
import 'session.dart';

/// Estimates the median step length for a [Session] using rolling time windows
/// to mitigate GPS noise and outliers.
class StepLengthEstimator {
  StepLengthEstimator._();

  /// Returns the estimated median step length in meters.
  ///
  /// Uses rolling windows over GPS distance and cumulative steps to derive
  /// per-window step lengths, then takes the median. Falls back to
  /// session-level distance / steps, or a default of 0.75 m.
  static double computeMedianStepLength(Session session) {
    final samples = <double>[];

    _collectWindowedStepLengths(
      session.positionSamples,
      session.stepSamples,
      samples,
    );

    final ref = session.trimmedReferenceSession;
    if (ref != null) {
      _collectWindowedStepLengths(
        ref.positionSamples,
        ref.stepSamples,
        samples,
      );
    }

    if (samples.isNotEmpty) {
      samples.sort();
      final median = samples[samples.length ~/ 2];
      return median.clamp(0.35, 1.35);
    }

    // Fallback: total session distance / total steps
    if (session.totalSteps != null &&
        session.totalSteps! > 20 &&
        session.distance > 10) {
      final avg = session.distance / session.totalSteps!;
      return avg.clamp(0.35, 1.35);
    }

    // Default average adult step length
    return 0.75;
  }

  static void _collectWindowedStepLengths(
    List<SensorSample> posList,
    List<SensorSample> stepList,
    List<double> outputSamples, {
    int windowSeconds = 10,
    int strideSeconds = 5,
  }) {
    if (posList.length < 2 || stepList.length < 2) return;

    final posT0 = posList.first.timestamp;
    final stepT0 = stepList.first.timestamp;

    // Build cumulative GPS distance curve
    final gpsTimeDist = <({double t, double d})>[];
    final firstDist = posList.first.values[PositionKeys.distance];
    double cumDist = 0.0;
    for (int i = 0; i < posList.length; i++) {
      final t =
          posList[i].timestamp.difference(posT0).inMilliseconds / 1000.0;
      final dVal = posList[i].values[PositionKeys.distance];

      if (firstDist != null && dVal != null) {
        cumDist = math.max(0.0, dVal - firstDist);
      } else if (i > 0) {
        cumDist += haversineDistance(
          lat1: posList[i - 1].values[PositionKeys.latitude]!,
          lon1: posList[i - 1].values[PositionKeys.longitude]!,
          lat2: posList[i].values[PositionKeys.latitude]!,
          lon2: posList[i].values[PositionKeys.longitude]!,
        );
      }
      gpsTimeDist.add((t: math.max(0.0, t), d: cumDist));
    }

    double getGpsDistAt(double t) {
      if (t <= gpsTimeDist.first.t) return gpsTimeDist.first.d;
      if (t >= gpsTimeDist.last.t) return gpsTimeDist.last.d;
      for (int i = 0; i < gpsTimeDist.length - 1; i++) {
        final p1 = gpsTimeDist[i];
        final p2 = gpsTimeDist[i + 1];
        if (p1.t <= t && t <= p2.t) {
          final dt = p2.t - p1.t;
          if (dt <= 0) return p1.d;
          return p1.d + (t - p1.t) / dt * (p2.d - p1.d);
        }
      }
      return gpsTimeDist.last.d;
    }

    // Build cumulative steps curve
    final stepTimeDist = <({double t, double steps})>[];
    final firstStep =
        stepList.first.values[StepKeys.cumulativeSteps] ?? 0.0;
    for (int i = 0; i < stepList.length; i++) {
      final t =
          stepList[i].timestamp.difference(stepT0).inMilliseconds / 1000.0;
      final rawVal =
          stepList[i].values[StepKeys.cumulativeSteps] ?? firstStep;
      stepTimeDist.add(
        (t: math.max(0.0, t), steps: math.max(0.0, rawVal - firstStep)),
      );
    }

    double getStepCountAt(double t) {
      if (t <= stepTimeDist.first.t) return stepTimeDist.first.steps;
      if (t >= stepTimeDist.last.t) return stepTimeDist.last.steps;
      for (int i = 0; i < stepTimeDist.length - 1; i++) {
        final p1 = stepTimeDist[i];
        final p2 = stepTimeDist[i + 1];
        if (p1.t <= t && t <= p2.t) {
          final dt = p2.t - p1.t;
          if (dt <= 0) return p1.steps;
          return p1.steps + (t - p1.t) / dt * (p2.steps - p1.steps);
        }
      }
      return stepTimeDist.last.steps;
    }

    final maxT =
        math.min(gpsTimeDist.last.t, stepTimeDist.last.t).toInt();

    for (int wStart = 0;
        wStart < maxT - windowSeconds;
        wStart += strideSeconds) {
      final wEnd = wStart + windowSeconds;
      final dGps =
          getGpsDistAt(wEnd.toDouble()) - getGpsDistAt(wStart.toDouble());
      final dSteps = getStepCountAt(wEnd.toDouble()) -
          getStepCountAt(wStart.toDouble());

      if (dGps > 0 && dSteps > 1.5) {
        final stepLen = dGps / dSteps;
        if (stepLen >= 0.25 && stepLen <= 2.0) {
          outputSamples.add(stepLen);
        }
      }
    }
  }
}
