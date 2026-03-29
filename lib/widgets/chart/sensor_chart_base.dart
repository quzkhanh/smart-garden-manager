import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sensor_reading.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class SensorChart extends StatefulWidget {
  final String sensorType;
  final List<SensorReading> readings;
  final String unit;
  final double minY;
  final double maxY;

  const SensorChart({
    super.key,
    required this.sensorType,
    required this.readings,
    required this.unit,
    this.minY = 0,
    this.maxY = 100,
  });

  @override
  State<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends State<SensorChart> {
  int? _touchedIndex;

  Color get _chartColor {
    switch (widget.sensorType) {
      case 'temperature':
        return AppColors.temperature;
      case 'air_humidity':
        return AppColors.humidity;
      case 'soil_moisture':
        return AppColors.soilMoisture;
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData get _icon {
    switch (widget.sensorType) {
      case 'temperature':
        return Icons.thermostat_rounded;
      case 'air_humidity':
        return Icons.water_drop_outlined;
      case 'soil_moisture':
        return Icons.grass_rounded;
      default:
        return Icons.sensors;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentValue = widget.readings.last.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _chartColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _chartColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.t(widget.sensorType),
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              '${currentValue.toStringAsFixed(1)}${widget.unit}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: _chartColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: LineChart(
            _buildChartData(isDark, theme),
            duration: const Duration(milliseconds: 350),
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(bool isDark, ThemeData theme) {
    if (widget.readings.isEmpty) return LineChartData();
    final spots = <FlSpot>[];
    final firstTime = widget.readings.first.timestamp;
    
    // Optimize performance: decimate data (1 point per hour)
    DateTime? lastAddedTime;
    for (var i = 0; i < widget.readings.length; i++) {
      final reading = widget.readings[i];
      
      if (lastAddedTime == null || 
          reading.timestamp.difference(lastAddedTime).inMinutes >= 60 || 
          i == widget.readings.length - 1) {
        final hoursFromStart = reading.timestamp.difference(firstTime).inMinutes / 60.0;
        spots.add(FlSpot(hoursFromStart, reading.value));
        lastAddedTime = reading.timestamp;
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getInterval(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _getInterval(),
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) return const SizedBox.shrink();
              return Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 6,
            getTitlesWidget: (value, meta) {
              if (widget.readings.isEmpty) return const SizedBox.shrink();
              final firstTime = widget.readings.first.timestamp;
              final time = firstTime.add(Duration(minutes: (value * 60).round()));
              final label = '${time.hour.toString().padLeft(2, '0')}:00';
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: spots.first.x,
      maxX: spots.last.x,
      minY: widget.minY,
      maxY: widget.maxY,
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (event, response) {
          setState(() {
            if (event is FlPointerExitEvent || response?.lineBarSpots == null) {
              _touchedIndex = null;
            } else {
              _touchedIndex = response?.lineBarSpots?.first.spotIndex;
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => isDark ? const Color(0xFF2A2D35) : Colors.white,
          tooltipBorder: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
          ),
          tooltipRoundedRadius: 10,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final firstTime = widget.readings.first.timestamp;
              final time = firstTime.add(Duration(minutes: (spot.x * 60).round()));
              final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              return LineTooltipItem(
                '$timeStr\n',
                TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: '${spot.y.toStringAsFixed(1)}${widget.unit}',
                    style: TextStyle(
                      color: _chartColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: _chartColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final isTouch = index == _touchedIndex;
              return FlDotCirclePainter(
                radius: isTouch ? 5 : 0,
                color: _chartColor,
                strokeWidth: 2,
                strokeColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _chartColor.withValues(alpha: 0.25),
                _chartColor.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  double _getInterval() {
    switch (widget.sensorType) {
      case 'temperature': return 10;
      case 'air_humidity': return 20;
      case 'soil_moisture': return 20;
      default: return 20;
    }
  }
}
