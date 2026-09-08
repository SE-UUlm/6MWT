import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/domain/haversine.dart';
import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';

enum ChartSeriesId {
  appGps,
  appSteps,
  refGps,
  refSteps,
}

class SeriesDescriptor {
  const SeriesDescriptor({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.unit,
    required this.isDashed,
  });

  final ChartSeriesId id;
  final String name;
  final String shortName;
  final Color color;
  final String unit;
  final bool isDashed;
}

class SessionChartData {
  SessionChartData._({
    required this.session,
    required this.appGpsSpots,
    required this.appStepSpots,
    required this.appRawStepCounts,
    required this.refGpsSpots,
    required this.refStepSpots,
    required this.refRawStepCounts,
    required this.medianStepLength,
    required this.maxTimeSeconds,
    required this.maxDistanceMeters,
  });

  factory SessionChartData.fromSession(Session session) {
    final startUtc = session.sessionStartUtc;

    // 1. App GPS Distance Spots
    final appGpsSpots = <FlSpot>[];
    final posSamples = session.positionSamples;
    if (posSamples.isNotEmpty) {
      double cumDist = 0.0;
      double? prevLat;
      double? prevLon;

      for (int i = 0; i < posSamples.length; i++) {
        final s = posSamples[i];
        final t = s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
        final lat = s.values[PositionKeys.latitude]!;
        final lon = s.values[PositionKeys.longitude]!;

        if (prevLat != null && prevLon != null) {
          cumDist += haversineDistance(
            lat1: prevLat,
            lon1: prevLon,
            lat2: lat,
            lon2: lon,
          );
        }
        prevLat = lat;
        prevLon = lon;

        _addOrUpdateSpot(appGpsSpots, math.max(0.0, t), cumDist);
      }
    }

    // 2. Compute median step length from App data + Reference data
    final medianStepLength = _computeMedianStepLength(session);

    // 3. App Step Spots (multiplied by medianStepLength to convert steps to meters)
    final appStepSpots = <FlSpot>[];
    final appRawStepCounts = <FlSpot>[];
    final stepSamples = session.stepSamples;
    if (stepSamples.isNotEmpty) {
      final firstStep = stepSamples.first.values[StepKeys.cumulativeSteps] ?? 0.0;
      for (final s in stepSamples) {
        final t = s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
        final rawVal = s.values[StepKeys.cumulativeSteps] ?? firstStep;
        final steps = math.max(0.0, rawVal - firstStep);
        final distanceMeters = steps * medianStepLength;
        final timeX = math.max(0.0, t);

        _addOrUpdateSpot(appRawStepCounts, timeX, steps);
        _addOrUpdateSpot(appStepSpots, timeX, distanceMeters);
      }
    }

    // 4. Reference GPS Distance Spots
    final refGpsSpots = <FlSpot>[];
    final trimmedRef = session.trimmedReferenceSession;
    if (trimmedRef != null && trimmedRef.positionSamples.isNotEmpty) {
      final refPos = trimmedRef.positionSamples;
      final firstRefDist = refPos.first.values[PositionKeys.distance];

      double cumDist = 0.0;
      double? prevLat;
      double? prevLon;

      for (final s in refPos) {
        final t = s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
        final lat = s.values[PositionKeys.latitude]!;
        final lon = s.values[PositionKeys.longitude]!;
        final dVal = s.values[PositionKeys.distance];

        if (firstRefDist != null && dVal != null) {
          cumDist = math.max(0.0, dVal - firstRefDist);
        } else {
          if (prevLat != null && prevLon != null) {
            cumDist += haversineDistance(
              lat1: prevLat,
              lon1: prevLon,
              lat2: lat,
              lon2: lon,
            );
          }
        }
        prevLat = lat;
        prevLon = lon;

        _addOrUpdateSpot(refGpsSpots, math.max(0.0, t), cumDist);
      }
    }

    // 5. Reference Step Spots (multiplied by same medianStepLength)
    final refStepSpots = <FlSpot>[];
    final refRawStepCounts = <FlSpot>[];
    if (trimmedRef != null && trimmedRef.stepSamples.isNotEmpty) {
      final refSteps = trimmedRef.stepSamples;
      final firstRefStep = refSteps.first.values[StepKeys.cumulativeSteps] ?? 0.0;
      for (final s in refSteps) {
        final t = s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
        final rawVal = s.values[StepKeys.cumulativeSteps] ?? firstRefStep;
        final steps = math.max(0.0, rawVal - firstRefStep);
        final distanceMeters = steps * medianStepLength;
        final timeX = math.max(0.0, t);

        _addOrUpdateSpot(refRawStepCounts, timeX, steps);
        _addOrUpdateSpot(refStepSpots, timeX, distanceMeters);
      }
    }

    // Compute max values
    double maxT = session.duration.toDouble();
    for (final list in [appGpsSpots, appStepSpots, refGpsSpots, refStepSpots]) {
      if (list.isNotEmpty) {
        maxT = math.max(maxT, list.last.x);
      }
    }

    double maxMeters = 100.0;
    for (final list in [appGpsSpots, appStepSpots, refGpsSpots, refStepSpots]) {
      for (final spot in list) {
        maxMeters = math.max(maxMeters, spot.y);
      }
    }

    return SessionChartData._(
      session: session,
      appGpsSpots: appGpsSpots,
      appStepSpots: appStepSpots,
      appRawStepCounts: appRawStepCounts,
      refGpsSpots: refGpsSpots,
      refStepSpots: refStepSpots,
      refRawStepCounts: refRawStepCounts,
      medianStepLength: medianStepLength,
      maxTimeSeconds: math.max(10.0, maxT),
      maxDistanceMeters: maxMeters,
    );
  }

  final Session session;
  final List<FlSpot> appGpsSpots;
  final List<FlSpot> appStepSpots;
  final List<FlSpot> appRawStepCounts;
  final List<FlSpot> refGpsSpots;
  final List<FlSpot> refStepSpots;
  final List<FlSpot> refRawStepCounts;
  final double medianStepLength;
  final double maxTimeSeconds;
  final double maxDistanceMeters;

  bool get hasReference =>
      refGpsSpots.isNotEmpty || refStepSpots.isNotEmpty;

  static const descriptors = {
    ChartSeriesId.appGps: SeriesDescriptor(
      id: ChartSeriesId.appGps,
      name: 'App GPS Distanz',
      shortName: 'App GPS',
      color: Color(0xFF2196F3), // Blue
      unit: 'm',
      isDashed: false,
    ),
    ChartSeriesId.appSteps: SeriesDescriptor(
      id: ChartSeriesId.appSteps,
      name: 'App Schritte (m)',
      shortName: 'App Schritte',
      color: Color(0xFFFF9800), // Orange
      unit: 'm',
      isDashed: false,
    ),
    ChartSeriesId.refGps: SeriesDescriptor(
      id: ChartSeriesId.refGps,
      name: 'Referenz GPS Distanz',
      shortName: 'Ref GPS',
      color: Color(0xFF4CAF50), // Green
      unit: 'm',
      isDashed: true,
    ),
    ChartSeriesId.refSteps: SeriesDescriptor(
      id: ChartSeriesId.refSteps,
      name: 'Referenz Schritte (m)',
      shortName: 'Ref Schritte',
      color: Color(0xFFAB47BC), // Purple
      unit: 'm',
      isDashed: true,
    ),
  };

  List<FlSpot> getSpots(ChartSeriesId id) => switch (id) {
        ChartSeriesId.appGps => appGpsSpots,
        ChartSeriesId.appSteps => appStepSpots,
        ChartSeriesId.refGps => refGpsSpots,
        ChartSeriesId.refSteps => refStepSpots,
      };

  double? valueAtTime(ChartSeriesId id, double timeSeconds) {
    final spots = getSpots(id);
    if (spots.isEmpty) return null;
    if (timeSeconds <= spots.first.x) return spots.first.y;
    if (timeSeconds >= spots.last.x) return spots.last.y;

    for (int i = 0; i < spots.length - 1; i++) {
      final p1 = spots[i];
      final p2 = spots[i + 1];
      if (p1.x <= timeSeconds && timeSeconds <= p2.x) {
        final dt = p2.x - p1.x;
        if (dt == 0) return p1.y;
        final factor = (timeSeconds - p1.x) / dt;
        return p1.y + factor * (p2.y - p1.y);
      }
    }
    return spots.last.y;
  }

  double? rawStepsAtTime(ChartSeriesId id, double timeSeconds) {
    final spots = id == ChartSeriesId.appSteps
        ? appRawStepCounts
        : id == ChartSeriesId.refSteps
            ? refRawStepCounts
            : null;
    if (spots == null || spots.isEmpty) return null;
    if (timeSeconds <= spots.first.x) return spots.first.y;
    if (timeSeconds >= spots.last.x) return spots.last.y;

    for (int i = 0; i < spots.length - 1; i++) {
      final p1 = spots[i];
      final p2 = spots[i + 1];
      if (p1.x <= timeSeconds && timeSeconds <= p2.x) {
        final dt = p2.x - p1.x;
        if (dt == 0) return p1.y;
        final factor = (timeSeconds - p1.x) / dt;
        return p1.y + factor * (p2.y - p1.y);
      }
    }
    return spots.last.y;
  }

  /// Estimates the median step length across App and Reference data
  /// using rolling time windows to mitigate GPS noise and outliers.
  static double _computeMedianStepLength(Session session) {
    final samples = <double>[];

    // Collect windowed step lengths from App data
    _collectWindowedStepLengths(
      session.positionSamples,
      session.stepSamples,
      samples,
    );

    // Also collect from Reference data if present
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
      // Median of the rolling samples
      final median = samples[samples.length ~/ 2];
      // Clamp to realistic adult walking step length range (0.3m to 1.4m)
      return median.clamp(0.35, 1.35);
    }

    // Fallback: total session distance / total steps
    if (session.totalSteps != null && session.totalSteps! > 20 && session.distance > 10) {
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
      final t = posList[i].timestamp.difference(posT0).inMilliseconds / 1000.0;
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
    final firstStep = stepList.first.values[StepKeys.cumulativeSteps] ?? 0.0;
    for (int i = 0; i < stepList.length; i++) {
      final t = stepList[i].timestamp.difference(stepT0).inMilliseconds / 1000.0;
      final rawVal = stepList[i].values[StepKeys.cumulativeSteps] ?? firstStep;
      stepTimeDist.add((t: math.max(0.0, t), steps: math.max(0.0, rawVal - firstStep)));
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

    final maxT = math.min(gpsTimeDist.last.t, stepTimeDist.last.t).toInt();

    for (int wStart = 0; wStart < maxT - windowSeconds; wStart += strideSeconds) {
      final wEnd = wStart + windowSeconds;
      final dGps = getGpsDistAt(wEnd.toDouble()) - getGpsDistAt(wStart.toDouble());
      final dSteps = getStepCountAt(wEnd.toDouble()) - getStepCountAt(wStart.toDouble());

      if (dGps > 0 && dSteps > 1.5) { // At least ~2 steps in window
        final stepLen = dGps / dSteps;
        // Exclude extreme GPS drift anomalies
        if (stepLen >= 0.25 && stepLen <= 2.0) {
          outputSamples.add(stepLen);
        }
      }
    }
  }

  static void _addOrUpdateSpot(List<FlSpot> list, double x, double y) {
    if (list.isNotEmpty && list.last.x == x) {
      list[list.length - 1] = FlSpot(x, y);
    } else {
      list.add(FlSpot(x, y));
    }
  }
}
