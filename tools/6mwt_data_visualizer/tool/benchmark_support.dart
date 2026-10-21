import 'package:six_minute_walk_test/core/sensors/pedometer_source.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/gps_step_distance_estimator.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';
import 'package:six_mwt_visualizer/core/domain/session.dart';
import 'package:six_mwt_visualizer/features/estimator_lab/estimator_replay.dart';

/// Mirrors the production configuration in walk_session_provider.dart.
GpsStepDistanceEstimator createProductionEstimator() =>
    GpsStepDistanceEstimator(stepSourceId: PedometerSource.id);

List<Session> benchmarkRecordings(Iterable<Session> sessions) =>
    sessions.expand((session) => session.recordings).toList()
      ..sort((a, b) => a.recordingLabel.compareTo(b.recordingLabel));

Future<List<Session>> loadBenchmarkRecordings(String directory) async =>
    benchmarkRecordings(
      (await SessionLoader.loadFromDataDirectory(directory)).sessions,
    );

/// Coverage is reference overlap / replay duration, not sensor quality.
List<Map<String, Object?>> compareReferences(
  Session recording,
  EstimatorReplay replay,
  ReplayResult result,
) {
  final base = <String, Object?>{
    'recording': recording.recordingLabel,
    'estimator': result.name,
  };
  if (replay.references.isEmpty) {
    return [
      {...base, 'status': 'no reference'},
    ];
  }
  return [
    for (final reference in replay.references)
      _compareReference(base, replay, result, reference),
  ];
}

Map<String, Object?> _compareReference(
  Map<String, Object?> base,
  EstimatorReplay replay,
  ReplayResult result,
  ReplayReference reference,
) {
  final row = <String, Object?>{
    ...base,
    'reference': reference.label,
    'manualReference': reference.manual,
  };
  final points = reference.points;
  if (points == null || points.isEmpty) {
    return {...row, 'status': 'no usable overlap'};
  }
  if (result.error != null || result.points.isEmpty) {
    return {...row, 'status': 'estimate unavailable'};
  }
  final start = points.first.seconds;
  final end = points.last.seconds;
  final measured =
      interpolateDistance(result.points, end) -
      interpolateDistance(result.points, start);
  final expected = points.last.meters - points.first.meters;
  final delta = measured - expected;
  return {
    ...row,
    'status': 'compared',
    'overlapStartSeconds': start,
    'overlapEndSeconds': end,
    'overlapSeconds': end - start,
    'coveragePercent': replay.duration > 0
        ? 100 * (end - start) / replay.duration
        : null,
    'estimatedMeters': measured,
    'referenceMeters': expected,
    'deltaMeters': delta,
    'absoluteErrorMeters': delta.abs(),
    'deltaPercent': expected == 0 ? null : 100 * delta / expected,
  };
}

Map<String, Object?> summarizeComparisons(Iterable<Map<String, Object?>> rows) {
  final valid = rows.where((row) => row['status'] == 'compared').toList();
  final percentages = valid.map((row) => row['deltaPercent']).whereType<num>();
  return {
    'pairs': valid.length,
    'percentagePairs': percentages.length,
    'maeMeters': valid.isEmpty
        ? null
        : valid.fold<double>(
                0,
                (sum, row) =>
                    sum + (row['absoluteErrorMeters'] as num).toDouble(),
              ) /
              valid.length,
    'mapePercent': percentages.isEmpty
        ? null
        : percentages.fold<double>(0, (sum, value) => sum + value.abs()) /
              percentages.length,
  };
}

String benchmarkNumber(Object? value) =>
    value is num ? value.toStringAsFixed(2) : '—';

String comparisonLine(Map<String, Object?> row) =>
    '${row['recording']} | ${row['estimator']} | '
    '${row['manualReference'] == true ? 'manual' : 'device'} '
    '${row['reference'] ?? '—'} | ${row['status']} | '
    '${benchmarkNumber(row['overlapStartSeconds'])}–'
    '${benchmarkNumber(row['overlapEndSeconds'])} s | '
    'coverage ${benchmarkNumber(row['coveragePercent'])}% | '
    'estimate ${benchmarkNumber(row['estimatedMeters'])} m | '
    'reference ${benchmarkNumber(row['referenceMeters'])} m | '
    'delta ${benchmarkNumber(row['deltaMeters'])} m / '
    '${benchmarkNumber(row['deltaPercent'])}% | '
    'absolute ${benchmarkNumber(row['absoluteErrorMeters'])} m';

List<String> summaryLines(List<Map<String, Object?>> rows) => [
  for (final manual in [false, true])
    for (final estimator in rows.map((row) => row['estimator']).toSet())
      '${manual ? 'manual' : 'device'} | $estimator | '
          '${summarizeComparisons(rows.where((row) => row['manualReference'] == manual && row['estimator'] == estimator))}',
];
