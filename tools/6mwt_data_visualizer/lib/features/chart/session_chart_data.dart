import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/domain/haversine.dart';
import '../../core/domain/sensor_sample.dart';
import '../../core/domain/session.dart';
import '../../core/domain/step_length_estimator.dart';

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
        final t =
            s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
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

    // 2. Compute median step length
    final medianStepLength =
        StepLengthEstimator.computeMedianStepLength(session);

    // 3. App Step Spots (steps x medianStepLength -> meters)
    final appStepSpots = <FlSpot>[];
    final appRawStepCounts = <FlSpot>[];
    final stepSamples = session.stepSamples;
    if (stepSamples.isNotEmpty) {
      final firstStep =
          stepSamples.first.values[StepKeys.cumulativeSteps] ?? 0.0;
      for (final s in stepSamples) {
        final t =
            s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
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
        final t =
            s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
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

    // 5. Reference Step Spots (steps x same medianStepLength)
    final refStepSpots = <FlSpot>[];
    final refRawStepCounts = <FlSpot>[];
    if (trimmedRef != null && trimmedRef.stepSamples.isNotEmpty) {
      final refSteps = trimmedRef.stepSamples;
      final firstRefStep =
          refSteps.first.values[StepKeys.cumulativeSteps] ?? 0.0;
      for (final s in refSteps) {
        final t =
            s.timestamp.toUtc().difference(startUtc).inMilliseconds / 1000.0;
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
    for (final list in [
      appGpsSpots,
      appStepSpots,
      refGpsSpots,
      refStepSpots,
    ]) {
      if (list.isNotEmpty) {
        maxT = math.max(maxT, list.last.x);
      }
    }

    double maxMeters = 100.0;
    for (final list in [
      appGpsSpots,
      appStepSpots,
      refGpsSpots,
      refStepSpots,
    ]) {
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

  bool get hasReference => refGpsSpots.isNotEmpty || refStepSpots.isNotEmpty;

  static const descriptors = {
    ChartSeriesId.appGps: SeriesDescriptor(
      id: ChartSeriesId.appGps,
      name: 'App GPS Distance',
      shortName: 'App GPS',
      color: Color(0xFF2196F3),
      unit: 'm',
      isDashed: false,
    ),
    ChartSeriesId.appSteps: SeriesDescriptor(
      id: ChartSeriesId.appSteps,
      name: 'App Steps (m)',
      shortName: 'App Steps',
      color: Color(0xFFFF9800),
      unit: 'm',
      isDashed: false,
    ),
    ChartSeriesId.refGps: SeriesDescriptor(
      id: ChartSeriesId.refGps,
      name: 'Reference GPS Distance',
      shortName: 'Ref GPS',
      color: Color(0xFF4CAF50),
      unit: 'm',
      isDashed: true,
    ),
    ChartSeriesId.refSteps: SeriesDescriptor(
      id: ChartSeriesId.refSteps,
      name: 'Reference Steps (m)',
      shortName: 'Ref Steps',
      color: Color(0xFFAB47BC),
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

  /// Linearly interpolates the Y value at [timeSeconds] in the given series.
  double? valueAtTime(ChartSeriesId id, double timeSeconds) {
    return _interpolate(getSpots(id), timeSeconds);
  }

  /// Returns the raw step count (before step-length conversion) at a given
  /// time. Returns `null` for non-step series.
  double? rawStepsAtTime(ChartSeriesId id, double timeSeconds) {
    final spots = switch (id) {
      ChartSeriesId.appSteps => appRawStepCounts,
      ChartSeriesId.refSteps => refRawStepCounts,
      _ => null,
    };
    if (spots == null) return null;
    return _interpolate(spots, timeSeconds);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Linearly interpolates between spot points at the given [x] value.
  static double? _interpolate(List<FlSpot> spots, double x) {
    if (spots.isEmpty) return null;
    if (x <= spots.first.x) return spots.first.y;
    if (x >= spots.last.x) return spots.last.y;

    for (int i = 0; i < spots.length - 1; i++) {
      final p1 = spots[i];
      final p2 = spots[i + 1];
      if (p1.x <= x && x <= p2.x) {
        final dt = p2.x - p1.x;
        if (dt == 0) return p1.y;
        final factor = (x - p1.x) / dt;
        return p1.y + factor * (p2.y - p1.y);
      }
    }
    return spots.last.y;
  }

  static void _addOrUpdateSpot(List<FlSpot> list, double x, double y) {
    if (list.isNotEmpty && list.last.x == x) {
      list[list.length - 1] = FlSpot(x, y);
    } else {
      list.add(FlSpot(x, y));
    }
  }
}
