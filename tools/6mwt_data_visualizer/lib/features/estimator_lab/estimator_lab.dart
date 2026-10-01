import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/domain/session.dart';
import '../../core/theme/reference_colors.dart';
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
  final Set<int> _hiddenReferences = {};
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLegend(),
        const SizedBox(height: 16),
        SizedBox(height: 320, child: _buildChart()),
        const SizedBox(height: 16),
        _buildResultsTable(),
      ],
    );
  }

  Widget _buildLegend() {
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
        for (final (i, reference) in _replay.references.indexed)
          Tooltip(
            message: reference.points == null
                ? 'No valid overlap with this recording.'
                : 'Reference coverage: ${reference.points!.first.seconds.toStringAsFixed(1)}–'
                      '${reference.points!.last.seconds.toStringAsFixed(1)} s. '
                      'Table deltas compare distances within this interval only.'
                      '${reference.manual ? " Timing is assumed constant speed, not measured." : ""}',
            child: FilterChip(
              avatar: CircleAvatar(
                backgroundColor: referenceColor(i),
                radius: 5,
              ),
              label: Text(
                '${reference.label} (${reference.points == null ? "unavailable" : "dashed"})',
              ),
              selected: !_hiddenReferences.contains(i),
              onSelected: (selected) => setState(() {
                if (selected) {
                  _hiddenReferences.remove(i);
                } else {
                  _hiddenReferences.add(i);
                }
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 56,
        dataRowMaxHeight: double.infinity,
        columns: [
          DataColumn(label: Text('Estimator / Reference')),
          DataColumn(label: Text('Distance (m)'), numeric: true),
          DataColumn(label: Text('Δ stored (m)'), numeric: true),
          for (final reference in _replay.references) ...[
            DataColumn(
              label: Text('Δ ${reference.name} (m)'),
              numeric: true,
              tooltip:
                  'Distance difference within the shared recording interval only.',
            ),
            DataColumn(label: Text('Δ ${reference.name} (%)'), numeric: true),
          ],
          DataColumn(label: Text('Additional info')),
        ],
        rows: [
          for (var i = 0; i < _results.length; i++) _buildResultRow(i),
          for (var i = 0; i < _replay.references.length; i++)
            _buildReferenceRow(i),
        ],
      ),
    );
  }

  DataRow _buildReferenceRow(int i) {
    final reference = _replay.references[i];
    final points = reference.points;
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: referenceColor(i)),
              const SizedBox(width: 8),
              Text('Reference: ${reference.label}'),
            ],
          ),
        ),
        DataCell(Text(points?.last.meters.toStringAsFixed(2) ?? '—')),
        // Reference rows show the comparison baseline, not estimator errors.
        for (
          var column = 0;
          column < 1 + 2 * _replay.references.length;
          column++
        )
          const DataCell(Text('—')),
        DataCell(
          Text(
            points == null
                ? 'No valid overlap with this recording.'
                : 'Reference coverage: ${points.first.seconds.toStringAsFixed(1)}–'
                      '${points.last.seconds.toStringAsFixed(1)} s',
          ),
        ),
      ],
    );
  }

  DataRow _buildResultRow(int i) {
    final result = _results[i];
    final distance = result.distance;
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
        for (final reference in _replay.references)
          ..._referenceCells(result, reference),
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

  List<DataCell> _referenceCells(
    ReplayResult result,
    ReplayReference reference,
  ) {
    final points = reference.points;
    final total = points?.last.meters;
    final delta = result.distance == null || points == null
        ? null
        : interpolateDistance(result.points, points.last.seconds) -
              interpolateDistance(result.points, points.first.seconds) -
              total!;
    final percent = delta == null || total == 0 ? null : delta / total! * 100;
    return [
      DataCell(Text(delta?.toStringAsFixed(2) ?? '—')),
      DataCell(Text(percent?.toStringAsFixed(2) ?? '—')),
    ];
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
          for (final (i, reference) in _replay.references.indexed)
            if (reference.points != null && !_hiddenReferences.contains(i))
              (
                name: reference.label,
                color: referenceColor(i),
                points: reference.points!,
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
