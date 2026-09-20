import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/features/chart/session_chart_data.dart';

void main() {
  test('Calculates chart series data for session without reference', () async {
    const filePath = '../../data/Basauri (fehlende Uhraufzeichnung)/session.json';
    if (!File(filePath).existsSync()) return;

    final data = await SessionLoader.load(filePath);
    final session = data.sessions.first;
    final chartData = SessionChartData.fromSession(session);

    expect(chartData.hasReference, isFalse);
    expect(chartData.appGpsSpots.isNotEmpty, isTrue);
    expect(chartData.appStepSpots.isNotEmpty, isTrue);
    expect(chartData.refGpsSpots.isEmpty, isTrue);
    expect(chartData.refStepSpots.isEmpty, isTrue);

    // Initial values should start at 0
    expect(chartData.appGpsSpots.first.y, 0.0);
    expect(chartData.appStepSpots.first.y, 0.0);

    // Final distance and steps should be positive
    expect(chartData.appGpsSpots.last.y, greaterThan(300.0));
    expect(chartData.appStepSpots.last.y, greaterThan(300.0));

    // Median step length is realistic and calculated
    expect(chartData.medianStepLength, greaterThan(0.4));
    expect(chartData.medianStepLength, lessThan(1.3));

    // Steps curve is converted to meters via medianStepLength
    final lastStepMeters = chartData.appStepSpots.last.y;
    final lastRawSteps = chartData.appRawStepCounts.last.y;
    expect(lastStepMeters, closeTo(lastRawSteps * chartData.medianStepLength, 0.001));

    // Raw step lookup
    final lastRawLookup = chartData.rawStepsAtTime(
      ChartSeriesId.appSteps,
      chartData.maxTimeSeconds,
    );
    expect(lastRawLookup, closeTo(lastRawSteps, 0.1));
  });

  test('Calculates chart series data with reference session', () async {
    const filePath = '../../data/Gräfenberg Wald 3/session.json';
    if (!File(filePath).existsSync()) return;

    final data = await SessionLoader.load(filePath);
    final session = data.sessions.first;
    final chartData = SessionChartData.fromSession(session);

    expect(chartData.hasReference, isTrue);
    expect(chartData.appGpsSpots.isNotEmpty, isTrue);
    expect(chartData.appStepSpots.isNotEmpty, isTrue);
    expect(chartData.refGpsSpots.isNotEmpty, isTrue);
    expect(chartData.refStepSpots.isNotEmpty, isTrue);

    // Reference values
    expect(chartData.refGpsSpots.last.y, greaterThan(100.0));
    expect(chartData.refStepSpots.last.y, greaterThan(50.0));

    // Interpolation at halfway for all active series
    final midTime = chartData.maxTimeSeconds / 2;
    final midAppGps = chartData.valueAtTime(ChartSeriesId.appGps, midTime);
    final midAppSteps = chartData.valueAtTime(ChartSeriesId.appSteps, midTime);
    final midRefGps = chartData.valueAtTime(ChartSeriesId.refGps, midTime);
    final midRefSteps = chartData.valueAtTime(ChartSeriesId.refSteps, midTime);

    expect(midAppGps, isNotNull);
    expect(midAppGps!, greaterThan(0.0));
    expect(midAppSteps, isNotNull);
    expect(midAppSteps!, greaterThan(0.0));
    expect(midRefGps, isNotNull);
    expect(midRefGps!, greaterThan(0.0));
    expect(midRefSteps, isNotNull);
    expect(midRefSteps!, greaterThan(0.0));

    // Raw step lookup for both App and Reference
    final rawAppSteps = chartData.rawStepsAtTime(ChartSeriesId.appSteps, midTime);
    final rawRefSteps = chartData.rawStepsAtTime(ChartSeriesId.refSteps, midTime);
    expect(rawAppSteps, isNotNull);
    expect(rawAppSteps!, greaterThan(0.0));
    expect(rawRefSteps, isNotNull);
    expect(rawRefSteps!, greaterThan(0.0));
  });

  test('Calculates realistic step length (~90 cm) for Gasteiz sessions', () async {
    for (final name in ['Gasteiz 1', 'Gasteiz 2']) {
      final filePath = '../../data/$name/session.json';
      if (!File(filePath).existsSync()) continue;

      final data = await SessionLoader.load(filePath);
      final session = data.sessions.first;
      final chartData = SessionChartData.fromSession(session);

      // Gasteiz step length should be ~0.91m (~91 cm), not over 1.0m
      expect(
        chartData.medianStepLength,
        greaterThanOrEqualTo(0.88),
        reason: '$name step length too small: ${chartData.medianStepLength}',
      );
      expect(
        chartData.medianStepLength,
        lessThanOrEqualTo(0.95),
        reason: '$name step length too large: ${chartData.medianStepLength}',
      );
    }
  });
}
