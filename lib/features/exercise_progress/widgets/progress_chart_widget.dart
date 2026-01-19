import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercise_progress_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/date_formatter.dart';

class ProgressChartWidget extends ConsumerWidget {
  final List<ExerciseProgressDataPoint> dataPoints;
  final String unit;
  /// 'weight' | 'reps' | 'time' | 'volume' | 'cardio_time' | 'cardio_distance' | 'cardio_pace'
  final String chartMode;
  /// Distance unit for cardio (km or mile)
  final String distanceUnit;

  const ProgressChartWidget({
    super.key,
    required this.dataPoints,
    required this.unit,
    this.chartMode = 'weight',
    this.distanceUnit = 'km',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    if (dataPoints.isEmpty) {
      return _buildEmptyState();
    }

    if (dataPoints.length < 2) {
      return _buildInsufficientDataState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getChartTitle(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: LineChart(
            _buildChartData(currentLanguage),
          ),
        ),
      ],
    );
  }

  String _getChartTitle() {
    switch (chartMode) {
      case 'time':
        return 'Top Time Progress';
      case 'reps':
        return 'Top Reps Progress';
      case 'volume':
        return 'Top Volume Progress';
      case 'cardio_time':
        return 'Total Time Progress';
      case 'cardio_distance':
        return 'Total Distance Progress';
      case 'cardio_pace':
        return 'Pace Progress';
      default:
        return 'Top Weight Progress';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No progress data available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Not enough data to show graph',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record at least 2 workouts to see progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(String language) {
    // Convert values based on chart mode
    final displayValues = dataPoints.map((d) {
      if (chartMode == 'cardio_distance') {
        // Convert meters to display unit
        if (distanceUnit == 'mile') {
          return d.topWeight / 1609.34;
        } else {
          return d.topWeight / 1000.0;
        }
      } else if (chartMode == 'cardio_pace') {
        // Speed is stored in km/h, convert to mph if needed
        if (distanceUnit == 'mile') {
          return d.topWeight / 1.60934;
        }
        return d.topWeight;
      }
      return d.topWeight;
    }).toList();

    // Create spots from display values
    final spots = displayValues.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value,
      );
    }).toList();

    // Find min and max for Y-axis
    final minValue = displayValues.reduce((a, b) => a < b ? a : b);
    final maxValue = displayValues.reduce((a, b) => a > b ? a : b);

    // Add padding to Y-axis
    final yPadding = (maxValue - minValue) * 0.2;
    final yMin = (minValue - yPadding).clamp(0.0, double.infinity);
    final yMax = maxValue + yPadding;
    
    // Calculate horizontal interval, ensuring it's never zero
    final yRange = yMax - yMin;
    final horizontalInterval = yRange > 0.0001
        ? yRange / 5
        : (yMax > 0 ? yMax * 0.2 : 1.0);

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
      minY: yMin,
      maxY: yMax,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _getReservedSize(),
            getTitlesWidget: (value, meta) {
              // Skip if this is min or max to avoid edge clipping
              if (value == meta.min || value == meta.max) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  _formatYAxisLabel(value),
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              // Only show labels for exact integer positions
              if (value != index.toDouble()) {
                return const SizedBox.shrink();
              }
              if (index < 0 || index >= dataPoints.length) {
                return const SizedBox.shrink();
              }

              // Show fewer labels if there are many data points
              final showEveryN = dataPoints.length > 7 ? 2 : 1;
              if (index % showEveryN != 0 && index != dataPoints.length - 1) {
                return const SizedBox.shrink();
              }

              final date = dataPoints[index].date;
              final dateStr = DateFormatter.formatVeryShortDate(date, language);
              final isFirst = index == 0;
              final isLast = index == dataPoints.length - 1;
              // Prevent the first/last label from being clipped by shifting it inward.
              final shiftX = isFirst ? 10.0 : (isLast ? -10.0 : 0.0);

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Transform.translate(
                  offset: Offset(shiftX, 0),
                  child: Text(
                    dateStr,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: horizontalInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipRoundedRadius: 8,
          tooltipMargin: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= dataPoints.length) {
                return null;
              }

              final dataPoint = dataPoints[index];
              final dateStr = DateFormatter.formatVeryShortDate(dataPoint.date, language);
              final tooltipText = _buildTooltipText(dateStr, dataPoint);

              return LineTooltipItem(
                tooltipText,
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  String _formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '0s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes <= 0) return '${seconds}s';
    return '${minutes}m${seconds.toString().padLeft(2, '0')}s';
  }

  double _getReservedSize() {
    switch (chartMode) {
      case 'time':
      case 'cardio_time':
        return 56;
      case 'cardio_pace':
        return 60;
      default:
        return 42;
    }
  }

  String _formatYAxisLabel(double value) {
    switch (chartMode) {
      case 'time':
      case 'cardio_time':
        return _formatSeconds(value.round());
      case 'reps':
        return value.round().toString();
      case 'cardio_distance':
        return '${value.toStringAsFixed(1)}$distanceUnit';
      case 'cardio_pace':
        return _formatSpeed(value);
      case 'volume':
        return '${value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1)}$unit';
      default:
        return '${value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1)}$unit';
    }
  }

  String _formatSpeed(double speed) {
    final speedUnit = distanceUnit == 'mile' ? 'mph' : 'km/h';
    return '${speed.toStringAsFixed(1)}$speedUnit';
  }

  String _formatDistance(double meters) {
    if (distanceUnit == 'mile') {
      final miles = meters / 1609.34;
      return '${miles.toStringAsFixed(2)} mile';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(2)}km';
  }

  String _buildTooltipText(String dateStr, ExerciseProgressDataPoint dataPoint) {
    switch (chartMode) {
      case 'time':
        return '$dateStr\n${_formatSeconds(dataPoint.topWeight.round())}';
      case 'reps':
        return '$dateStr\n${dataPoint.topWeight.round()} reps';
      case 'volume':
        final weight = dataPoint.weight;
        final reps = dataPoint.reps;
        if (weight != null && reps != null) {
          final weightStr = weight % 1 == 0
              ? weight.toInt().toString()
              : weight.toStringAsFixed(1);
          return '$dateStr\n${dataPoint.topWeight.toStringAsFixed(1)}$unit\n($weightStr$unit/$reps reps)';
        }
        return '$dateStr\n${dataPoint.topWeight.toStringAsFixed(1)}$unit';
      case 'cardio_time':
        return '$dateStr\n${_formatSeconds(dataPoint.topWeight.round())}';
      case 'cardio_distance':
        return '$dateStr\n${_formatDistance(dataPoint.topWeight)}';
      case 'cardio_pace':
        final displaySpeed = distanceUnit == 'mile'
            ? dataPoint.topWeight / 1.60934
            : dataPoint.topWeight;
        return '$dateStr\n${_formatSpeed(displaySpeed)}';
      default:
        return '$dateStr\n${dataPoint.topWeight.toStringAsFixed(1)}$unit';
    }
  }
}
