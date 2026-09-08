import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/domain/session.dart';
import 'session_chart_data.dart';

class DistanceStepsChart extends StatefulWidget {
  const DistanceStepsChart({
    super.key,
    required this.session,
    this.onClose,
  });

  final Session session;
  final VoidCallback? onClose;

  @override
  State<DistanceStepsChart> createState() => _DistanceStepsChartState();
}

class _DistanceStepsChartState extends State<DistanceStepsChart> {
  late SessionChartData _chartData;

  // Active series toggles
  final Set<ChartSeriesId> _activeSeries = {
    ChartSeriesId.appGps,
    ChartSeriesId.appSteps,
    ChartSeriesId.refGps,
    ChartSeriesId.refSteps,
  };

  @override
  void initState() {
    super.initState();
    _chartData = SessionChartData.fromSession(widget.session);
  }

  @override
  void didUpdateWidget(DistanceStepsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id ||
        oldWidget.session.hasReference != widget.session.hasReference) {
      _chartData = SessionChartData.fromSession(widget.session);
    }
  }

  void _toggleSeries(ChartSeriesId id) {
    setState(() {
      if (_activeSeries.contains(id)) {
        if (_activeSeries.length > 1) {
          _activeSeries.remove(id);
        }
      } else {
        _activeSeries.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header toolbar
          _ChartToolbar(
            hasReference: _chartData.hasReference,
            medianStepLength: _chartData.medianStepLength,
            activeSeries: _activeSeries,
            onToggleSeries: _toggleSeries,
            onClose: widget.onClose,
          ),
          const Divider(height: 1),
          // Chart view
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
              child: _buildLineChart(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate Y-axis boundaries in meters
    double maxVal = 50.0;
    for (final id in _activeSeries) {
      final spots = _chartData.getSpots(id);
      for (final s in spots) {
        maxVal = math.max(maxVal, s.y);
      }
    }
    final maxY = (maxVal * 1.1).ceilToDouble();
    final maxX = _chartData.maxTimeSeconds;

    // Build bars for active series
    final lineBarsData = <LineChartBarData>[];

    for (final id in ChartSeriesId.values) {
      if (!_activeSeries.contains(id)) continue;
      final desc = SessionChartData.descriptors[id]!;
      final spots = _chartData.getSpots(id);
      if (spots.isEmpty) continue;

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: desc.color,
          barWidth: desc.isDashed ? 2.2 : 2.8,
          isStrokeCapRound: true,
          dashArray: desc.isDashed ? [6, 4] : null,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: !desc.isDashed,
            color: desc.color.withValues(alpha: 0.04),
          ),
        ),
      );
    }

    if (lineBarsData.isEmpty) {
      return const Center(
        child: Text('Keine Signale ausgewählt.'),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineTouchData: _buildTouchData(context),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _calculateYInterval(maxY),
          verticalInterval: _calculateXInterval(maxX),
          getDrawingHorizontalLine: (val) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (val) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: _calculateYInterval(maxY),
              getTitlesWidget: (val, meta) {
                if (val == meta.max) return const SizedBox.shrink();
                final text = val >= 1000
                    ? '${(val / 1000).toStringAsFixed(1)}k m'
                    : '${val.toInt()} m';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _calculateXInterval(maxX),
              getTitlesWidget: (val, meta) {
                if (val < 0 || val > maxX) return const SizedBox.shrink();
                final minutes = val ~/ 60;
                final seconds = (val % 60).toInt();
                final text =
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: colorScheme.outlineVariant, width: 1),
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
            right: BorderSide.none,
            top: BorderSide.none,
          ),
        ),
        lineBarsData: lineBarsData,
      ),
    );
  }

  LineTouchData _buildTouchData(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchSpotThreshold: 50,
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((spotIndex) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.8),
              strokeWidth: 1.5,
              dashArray: [4, 4],
            ),
            FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: barData.color ?? colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
          );
        }).toList();
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) =>
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        tooltipBorderRadius: BorderRadius.circular(8),
        tooltipBorder: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        maxContentWidth: 280,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        getTooltipItems: (touchedSpots) {
          if (touchedSpots.isEmpty) return [];

          // The time at the hovered position
          final x = touchedSpots.first.x;
          final m = x ~/ 60;
          final s = (x % 60).toInt();
          final timeStr =
              '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} (${x.toInt()}s)';

          // fl_chart requires the returned list to have the exact same length as touchedSpots.
          // We put all formatted values into the first item and fill the rest with null.
          final spans = <TextSpan>[];

          for (final id in ChartSeriesId.values) {
            if (!_activeSeries.contains(id)) continue;
            final desc = SessionChartData.descriptors[id]!;
            final metersVal = _chartData.valueAtTime(id, x);
            if (metersVal == null) continue;

            final rawSteps = _chartData.rawStepsAtTime(id, x);

            String valText = '${metersVal.toStringAsFixed(1)} m';
            if (rawSteps != null) {
              valText += ' (${rawSteps.round()} Schritte)';
            }

            spans.add(
              TextSpan(
                text: '\n● ${desc.name}: $valText',
                style: TextStyle(
                  color: desc.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final firstItem = LineTooltipItem(
            'Zeit: $timeStr',
            TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.left,
            children: spans,
          );

          return [
            firstItem,
            ...List<LineTooltipItem?>.filled(touchedSpots.length - 1, null),
          ];
        },
      ),
    );
  }

  double _calculateXInterval(double maxX) {
    if (maxX <= 120) return 30.0;
    if (maxX <= 360) return 60.0;
    if (maxX <= 720) return 120.0;
    return 300.0;
  }

  double _calculateYInterval(double maxY) {
    if (maxY <= 50) return 10.0;
    if (maxY <= 150) return 25.0;
    if (maxY <= 400) return 50.0;
    if (maxY <= 800) return 100.0;
    return 200.0;
  }
}

// ---------------------------------------------------------------------------
// Toolbar: Legend, Toggle Chips & Step Length Badge
// ---------------------------------------------------------------------------

class _ChartToolbar extends StatelessWidget {
  const _ChartToolbar({
    required this.hasReference,
    required this.medianStepLength,
    required this.activeSeries,
    required this.onToggleSeries,
    this.onClose,
  });

  final bool hasReference;
  final double medianStepLength;
  final Set<ChartSeriesId> activeSeries;
  final void Function(ChartSeriesId) onToggleSeries;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainer,
      child: Row(
        children: [
          Icon(Icons.show_chart, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Signalverlauf (Distanz & Schritte in Metern)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          // Series filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(context, ChartSeriesId.appGps),
                  const SizedBox(width: 6),
                  _buildChip(context, ChartSeriesId.appSteps),
                  if (hasReference) ...[
                    const SizedBox(width: 12),
                    Container(
                      height: 16,
                      width: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    _buildChip(context, ChartSeriesId.refGps),
                    const SizedBox(width: 6),
                    _buildChip(context, ChartSeriesId.refSteps),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Estimated Median Step Length Badge
          Tooltip(
            message:
                'Aus der Session berechnete Median-Schrittlänge über rollende Zeitfenster.\nSchritte werden mit diesem Faktor multipliziert, um eine Distanz in Metern zu erhalten.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.straighten, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Schrittlänge: ~${(medianStepLength * 100).toStringAsFixed(0)} cm',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Diagramm schließen',
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, ChartSeriesId id) {
    final desc = SessionChartData.descriptors[id]!;
    final isSelected = activeSeries.contains(id);

    return FilterChip(
      label: Text(desc.name, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => onToggleSeries(id),
      selectedColor: desc.color.withValues(alpha: 0.25),
      checkmarkColor: desc.color,
      side: BorderSide(
        color: isSelected ? desc.color : Theme.of(context).colorScheme.outlineVariant,
        width: isSelected ? 1.2 : 0.8,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: desc.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
