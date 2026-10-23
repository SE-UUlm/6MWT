import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:six_minute_walk_test/features/walk/presentation/distance_confidence_format.dart';

import '../../core/domain/session.dart';
import '../../core/theme/reference_colors.dart';
import 'estimator_replay.dart';
import 'session_replay_cache.dart';

/// Displays the code-configured estimators for the selected recording.
class EstimatorLab extends StatefulWidget {
  const EstimatorLab({super.key, required this.session, this.replayLoader});
  final ReplayLoader? replayLoader;
  final Session session;

  @override
  State<EstimatorLab> createState() => _EstimatorLabState();
}

class _EstimatorLabState extends State<EstimatorLab> {
  final ScrollController _tableScrollController = ScrollController();
  final Set<(int, int)> _hidden = {};
  final Set<(int, int)> _hiddenReferences = {};
  final Set<(int, int)> _expandedInfo = {};
  int _graphMode = 0;
  int _selectedRecording = 0;
  int _selectedEstimator = 0;
  bool _loading = true;
  Object? _error;
  int _generation = 0;
  late List<EstimatorReplay> _replays;
  late List<List<ReplayResult>> _runs;
  List<ReplayResult> get _results => _runs.first;
  double get _duration => _replays.map((r) => r.duration).fold(0, math.max);
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
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
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
    _loading = true;
    _error = null;
    final generation = ++_generation;
    final load = widget.replayLoader ?? sessionReplayCache.load;
    load(widget.session).then(
      (result) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _replays = result.replays;
          _runs = result.runs;
          _loading = false;
        });
      },
      onError: (Object error, StackTrace stack) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _loading = false;
          _error = error;
        });
      },
    );
    _hidden.clear();
    _hiddenReferences.clear();
    _expandedInfo.clear();
    _selectedRecording = 0;
    _selectedEstimator = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Calculating estimators…'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not replay session: $_error'),
            TextButton(
              onPressed: () => setState(_run),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.session.isGroup) _buildGraphSelection(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: SingleChildScrollView(child: _buildLegend()),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 320, child: _buildChart()),
        const SizedBox(height: 16),
        _buildResultsTable(),
      ],
    );
  }

  bool _includes(int recording, int estimator) =>
      (_graphMode != 1 || recording == _selectedRecording) &&
      (_graphMode != 2 || estimator == _selectedEstimator);

  Color _curveColor(int recording, int estimator) => widget.session.isGroup
      ? HSVColor.fromAHSV(
          1,
          (estimator * 137.508 + recording * 47) % 360,
          .7,
          .8,
        ).toColor()
      : _colors[estimator % _colors.length];

  String _curveName(int recording, int estimator) => widget.session.isGroup
      ? '${widget.session.recordings[recording].deviceLabel} · #${estimator + 1}'
      : '#${estimator + 1}';

  String _referenceName(int recording, ReplayReference reference) =>
      widget.session.isGroup
      ? '${widget.session.recordings[recording].deviceLabel} · ${reference.label}'
      : reference.label;

  Widget _buildGraphSelection() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        DropdownButton<int>(
          value: _graphMode,
          items: const [
            DropdownMenuItem(
              value: 0,
              child: Text('All estimators and subsessions'),
            ),
            DropdownMenuItem(
              value: 1,
              child: Text('All estimators of one subsession'),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('All subsessions of one estimator'),
            ),
          ],
          onChanged: (value) => setState(() => _graphMode = value!),
        ),
        if (_graphMode == 1)
          DropdownButton<int>(
            value: _selectedRecording,
            items: [
              for (final (i, recording) in widget.session.recordings.indexed)
                DropdownMenuItem(value: i, child: Text(recording.deviceLabel)),
            ],
            onChanged: (value) => setState(() => _selectedRecording = value!),
          ),
        if (_graphMode == 2)
          DropdownButton<int>(
            value: _selectedEstimator,
            items: [
              for (final (i, result) in _results.indexed)
                DropdownMenuItem(
                  value: i,
                  child: Text('#${i + 1} ${result.name}'),
                ),
            ],
            onChanged: (value) => setState(() => _selectedEstimator = value!),
          ),
        const Text(
          'Time is relative to each subsession’s first sensor sample.',
        ),
      ],
    ),
  );

  Widget _buildLegend() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (r, results) in _runs.indexed)
        for (final (i, result) in results.indexed)
          if (_includes(r, i))
            FilterChip(
              avatar: CircleAvatar(
                backgroundColor: _curveColor(r, i),
                radius: 5,
              ),
              label: Text('${_curveName(r, i)} ${result.name}'),
              selected: !_hidden.contains((r, i)),
              onSelected: (selected) => setState(() {
                if (selected) {
                  _hidden.remove((r, i));
                } else {
                  _hidden.add((r, i));
                }
              }),
            ),
      for (final (r, replay) in _replays.indexed)
        if (_graphMode != 1 || r == _selectedRecording)
          for (final (i, reference) in replay.references.indexed)
            Tooltip(
              message: _coverage(reference),
              child: FilterChip(
                avatar: CircleAvatar(
                  backgroundColor: referenceColor(i),
                  radius: 5,
                ),
                label: Text(
                  '${_referenceName(r, reference)} (${reference.points == null ? "unavailable" : "dashed"})',
                ),
                selected: !_hiddenReferences.contains((r, i)),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _hiddenReferences.remove((r, i));
                  } else {
                    _hiddenReferences.add((r, i));
                  }
                }),
              ),
            ),
    ],
  );

  String _number(double? value) => value?.toStringAsFixed(2) ?? '—';

  String _coverage(ReplayReference reference) => reference.points == null
      ? 'No valid overlap with this recording.'
      : 'Reference coverage: ${reference.points!.first.seconds.toStringAsFixed(1)}–'
            '${reference.points!.last.seconds.toStringAsFixed(1)} s. Deltas use this interval only.';

  Widget _buildResultsTable() => Scrollbar(
    controller: _tableScrollController,
    thumbVisibility: true,
    trackVisibility: true,
    interactive: true,
    thickness: 10,
    scrollbarOrientation: ScrollbarOrientation.bottom,
    child: SingleChildScrollView(
      controller: _tableScrollController,
      primary: false,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 16),
      child: DataTable(
        dataRowMinHeight: 56,
        dataRowMaxHeight: double.infinity,
        columns: [
          const DataColumn(label: Text('Estimator / Reference')),
          for (final recording in widget.session.recordings)
            DataColumn(label: Text(recording.deviceLabel)),
        ],
        rows: [
          for (final (i, result) in _results.indexed)
            DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: _curveColor(0, i)),
                      const SizedBox(width: 8),
                      Text('#${i + 1} ${result.name}'),
                    ],
                  ),
                ),
                for (var r = 0; r < _runs.length; r++) _resultCell(r, i),
              ],
            ),
          for (var i = 0; i < widget.session.references.length; i++)
            DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: referenceColor(i)),
                      const SizedBox(width: 8),
                      Text('Reference: ${_replays.first.references[i].label}'),
                    ],
                  ),
                ),
                for (final replay in _replays)
                  DataCell(
                    Tooltip(
                      message: _coverage(replay.references[i]),
                      child: Text(
                        '${_number(replay.references[i].points?.last.meters)} m',
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
  );

  DataCell _resultCell(int recording, int estimator) {
    final result = _runs[recording][estimator];
    final distance = result.distance;
    final expanded = _expandedInfo.contains((recording, estimator));
    return DataCell(
      SizedBox(
        width: 250,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_number(distance)} m',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _curveColor(recording, estimator),
                ),
              ),
              if (result.error != null) Text('Error: ${result.error}'),
              if (result.error == null && result.confidence != null)
                Text(
                  'Confidence: ${formatConfidence(result.confidence)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: confidenceColor(result.confidence),
                  ),
                ),
              Text(
                'Δ stored: ${_number(distance == null ? null : distance - widget.session.recordings[recording].distance)} m',
              ),
              for (final reference in _replays[recording].references)
                Tooltip(
                  message: _coverage(reference),
                  child: Text(_deltaText(result, reference)),
                ),
              if (result.additionalInfo.isNotEmpty) ...[
                TextButton.icon(
                  key: ValueKey('info-$recording-$estimator'),
                  onPressed: () => setState(() {
                    if (expanded) {
                      _expandedInfo.remove((recording, estimator));
                    } else {
                      _expandedInfo.add((recording, estimator));
                    }
                  }),
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  label: const Text('Additional info'),
                ),
                if (expanded)
                  Text(
                    result.additionalInfo.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _deltaText(ReplayResult result, ReplayReference reference) {
    final points = reference.points;
    final total = points?.last.meters;
    final delta = result.distance == null || points == null
        ? null
        : interpolateDistance(result.points, points.last.seconds) -
              interpolateDistance(result.points, points.first.seconds) -
              total!;
    final percent = delta == null || total == 0 ? null : delta / total! * 100;
    return 'Δ ${reference.name}: ${_number(delta)} m (${_number(percent)}%)';
  }

  Widget _buildChart() {
    final colors = Theme.of(context).colorScheme;
    final curves =
        <({String name, Color color, List<DistancePoint> points, bool dashed})>[
          for (final (r, results) in _runs.indexed)
            for (final (i, result) in results.indexed)
              if (_includes(r, i) &&
                  !_hidden.contains((r, i)) &&
                  result.points.isNotEmpty)
                (
                  name: _curveName(r, i),
                  color: _curveColor(r, i),
                  points: result.chartPoints,
                  dashed: false,
                ),
          for (final (r, replay) in _replays.indexed)
            if (_graphMode != 1 || r == _selectedRecording)
              for (final (i, reference) in replay.references.indexed)
                if (reference.points != null &&
                    !_hiddenReferences.contains((r, i)))
                  (
                    name: _referenceName(r, reference),
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
        maxX: math.max(1, _duration),
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
              interval: math.max(1, (_duration / 6).ceilToDouble()),
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
