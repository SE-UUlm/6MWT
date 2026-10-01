import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/domain/session.dart';
import 'estimator_replay.dart';
import 'estimators.dart';

/// Displays the code-configured estimators for the selected recording.
class EstimatorLab extends StatefulWidget {
  const EstimatorLab({super.key, required this.session});
  final Session session;

  @override
  State<EstimatorLab> createState() => _EstimatorLabState();
}

class _EstimatorLabState extends State<EstimatorLab> {
  final Set<int> _hidden = {};
  late EstimatorReplay _replay;
  late List<ReplayResult> _results;
  static const _colors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(EstimatorLab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session)) {
      _run();
    }
  }

  /// New instances isolate each session; replay resets every estimator before use.
  void _run() {
    _replay = EstimatorReplay(widget.session);
    _results = createEstimators().map(_replay.run).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ref = _replay.reference?.last.meters;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLegend(ref),
        const SizedBox(height: 16),
        SizedBox(height: 320, child: _buildChart()),
        const SizedBox(height: 16),
        _buildResultsTable(ref),
      ],
    );
  }

  Widget _buildLegend(double? referenceDistance) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _results.length; i++)
          FilterChip(
            avatar: CircleAvatar(
              backgroundColor: _colors[i % _colors.length],
              radius: 5,
            ),
            label: Text('#${i + 1} ${_results[i].name}'),
            selected: !_hidden.contains(i),
            onSelected: (selected) => setState(() {
              if (selected) {
                _hidden.remove(i);
              } else {
                _hidden.add(i);
              }
            }),
          ),
        if (referenceDistance != null)
          Tooltip(
            message:
                'Reference coverage: ${_replay.reference!.first.seconds.toStringAsFixed(1)}–'
                '${_replay.reference!.last.seconds.toStringAsFixed(1)} s. '
                'Reference distance starts at zero at the beginning of this interval; '
                'table deltas compare distances within this interval only.',
            child: const Chip(
              avatar: CircleAvatar(backgroundColor: Colors.green, radius: 5),
              label: Text('Reference (dashed)'),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsTable(double? referenceDistance) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 56,
        dataRowMaxHeight: double.infinity,
        columns: const [
          DataColumn(label: Text('Estimator')),
          DataColumn(label: Text('Distance (m)'), numeric: true),
          DataColumn(label: Text('Δ stored (m)'), numeric: true),
          DataColumn(
            label: Text('Δ reference (m)'),
            numeric: true,
            tooltip:
                'Distance difference within the shared recording interval only.',
          ),
          DataColumn(
            label: Text('Δ reference (%)'),
            numeric: true,
            tooltip:
                'Percentage difference within the shared recording interval only.',
          ),
          DataColumn(label: Text('Additional info')),
        ],
        rows: [
          for (var i = 0; i < _results.length; i++)
            _buildResultRow(i, referenceDistance),
        ],
      ),
    );
  }

  DataRow _buildResultRow(int i, double? reference) {
    final result = _results[i];
    final distance = result.distance;
    final referencePoints = _replay.reference;
    // Compare equal intervals even if the reference starts late or ends early.
    final overlapDistance = distance == null || referencePoints == null
        ? null
        : interpolateDistance(result.points, referencePoints.last.seconds) -
              interpolateDistance(result.points, referencePoints.first.seconds);
    final delta = overlapDistance == null || reference == null
        ? null
        : overlapDistance - reference;
    String number(double? value) => value?.toStringAsFixed(2) ?? '—';
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: _colors[i % _colors.length]),
              const SizedBox(width: 8),
              Text(
                '#${i + 1} ${result.name}${result.error == null ? '' : '\nError: ${result.error}'}',
              ),
            ],
          ),
        ),
        DataCell(Text(number(distance))),
        DataCell(
          Text(
            number(
              distance == null ? null : distance - widget.session.distance,
            ),
          ),
        ),
        DataCell(Text(number(delta))),
        DataCell(
          Text(
            number(
              delta == null || reference == 0 ? null : delta / reference! * 100,
            ),
          ),
        ),
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              result.additionalInfo.isEmpty
                  ? '—'
                  : result.additionalInfo.entries
                        .map((entry) => '${entry.key}: ${entry.value}')
                        .join('\n'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final colors = Theme.of(context).colorScheme;
    final curves =
        <({String name, Color color, List<DistancePoint> points, bool dashed})>[
          for (var i = 0; i < _results.length; i++)
            if (!_hidden.contains(i) && _results[i].points.isNotEmpty)
              (
                name: '#${i + 1}',
                color: _colors[i % _colors.length],
                points: _results[i].chartPoints,
                dashed: false,
              ),
          if (_replay.reference != null)
            (
              name: 'Reference',
              color: Colors.green,
              points: _replay.reference!,
              dashed: true,
            ),
        ];
    if (curves.isEmpty) {
      return const Center(child: Text('No replay data to display.'));
    }
    final maxY = curves
        .expand((curve) => curve.points)
        .fold<double>(10, (max, p) => math.max(max, p.meters));
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, _replay.duration),
        minY: 0,
        maxY: maxY * 1.1,
        clipData: const FlClipData.all(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            axisNameWidget: Text('Distance (m)'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 48),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Replay time (mm:ss)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: math.max(1, (_replay.duration / 6).ceilToDouble()),
              getTitlesWidget: (value, meta) => Text(
                '${value ~/ 60}:${(value.toInt() % 60).toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // Neutral text stays readable regardless of the series color.
            getTooltipColor: (_) => colors.surfaceContainerHighest,
            tooltipBorder: BorderSide(color: colors.outline),
            maxContentWidth: 320,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              if (spots.isEmpty) return [];
              final time = spots.first.x;
              // Hit testing may omit sparse or distant curves. Evaluate every
              // visible curve at one time, preserving #1, #2, ... Reference order.
              final entries = <TextSpan>[];
              for (final curve in curves) {
                final covered =
                    time >= curve.points.first.seconds &&
                    time <= curve.points.last.seconds;
                final value = covered
                    ? '${interpolateDistance(curve.points, time).toStringAsFixed(2)} m'
                    : '— (outside recording)';
                // Color only the marker; keep values in the readable theme color.
                entries.add(
                  TextSpan(
                    text: '\n● ',
                    style: TextStyle(color: curve.color),
                  ),
                );
                entries.add(TextSpan(text: '${curve.name}: $value'));
              }
              // fl_chart requires one item per hit. Use one combined tooltip
              // and null placeholders so missing hits cannot hide reference data.
              return [
                LineTooltipItem(
                  'Time: ${time.toStringAsFixed(1)} s',
                  TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.left,
                  children: entries,
                ),
                ...List<LineTooltipItem?>.filled(spots.length - 1, null),
              ];
            },
          ),
        ),
        lineBarsData: [
          for (final curve in curves)
            LineChartBarData(
              spots: [
                for (final point in curve.points)
                  FlSpot(point.seconds, point.meters),
              ],
              color: curve.color,
              barWidth: 2,
              isCurved: false,
              dashArray: curve.dashed ? [6, 4] : null,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
