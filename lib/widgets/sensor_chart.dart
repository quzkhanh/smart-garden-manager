import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_reading.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// A beautiful line chart showing 24h sensor data for a specific sensor type.
/// Designed with a clean architecture for easy Firebase integration:
/// just replace the `readings` parameter with data from Firestore.
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

    // Current value (latest reading)
    final currentValue = widget.readings.last.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with icon, label, and current value
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

        // Chart
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
    final spots = <FlSpot>[];
    if (widget.readings.isEmpty) return LineChartData();

    final firstTime = widget.readings.first.timestamp;

    for (var i = 0; i < widget.readings.length; i++) {
      final reading = widget.readings[i];
      final hoursFromStart =
          reading.timestamp.difference(firstTime).inMinutes / 60.0;
      spots.add(FlSpot(hoursFromStart, reading.value));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getInterval(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
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
              if (value == meta.max || value == meta.min) {
                return const SizedBox.shrink();
              }
              return Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
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
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    fontSize: 10,
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
          getTooltipColor: (spot) => isDark
              ? const Color(0xFF2A2D35)
              : Colors.white,
          tooltipBorder: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          tooltipRoundedRadius: 10,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final firstTime = widget.readings.first.timestamp;
              final time = firstTime.add(
                Duration(minutes: (spot.x * 60).round()),
              );
              final timeStr =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              return LineTooltipItem(
                '$timeStr\n',
                TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
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
                strokeColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
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
      case 'temperature':
        return 10;
      case 'air_humidity':
        return 20;
      case 'soil_moisture':
        return 20;
      default:
        return 20;
    }
  }
}

/// A card that displays a tabbed view of all 3 sensor charts (24h history).
/// Simply pass a [SensorHistory] object - in production this comes from Firebase.
class SensorChartCard extends StatefulWidget {
  final SensorHistory history;

  const SensorChartCard({super.key, required this.history});

  @override
  State<SensorChartCard> createState() => _SensorChartCardState();
}

class _SensorChartCardState extends State<SensorChartCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabs = [
      _ChartTab(
        type: 'temperature',
        label: l10n.t('temperature'),
        color: AppColors.temperature,
        icon: Icons.thermostat_rounded,
      ),
      _ChartTab(
        type: 'air_humidity',
        label: l10n.t('air_humidity'),
        color: AppColors.humidity,
        icon: Icons.water_drop_outlined,
      ),
      _ChartTab(
        type: 'soil_moisture',
        label: l10n.t('soil_moisture'),
        color: AppColors.soilMoisture,
        icon: Icons.grass_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.t('chart_24h'),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tab bar
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              indicator: BoxDecoration(
                color: tabs[_tabController.index].color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tabs[_tabController.index].color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: tabs[_tabController.index].color,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: EdgeInsets.zero,
              tabs: tabs.map((t) => Tab(
                height: 34,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        t.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Chart content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              key: ValueKey(_tabController.index),
              height: 210,
              child: _buildChart(tabs[_tabController.index]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChart(_ChartTab tab) {
    final readings = widget.history.getReadings(tab.type);

    double minY, maxY;
    String unit;
    switch (tab.type) {
      case 'temperature':
        minY = 0;
        maxY = 50;
        unit = '°C';
        break;
      case 'air_humidity':
        minY = 0;
        maxY = 100;
        unit = '%';
        break;
      case 'soil_moisture':
        minY = 0;
        maxY = 100;
        unit = '%';
        break;
      default:
        minY = 0;
        maxY = 100;
        unit = '';
    }

    return SensorChart(
      sensorType: tab.type,
      readings: readings,
      unit: unit,
      minY: minY,
      maxY: maxY,
    );
  }
}

class _ChartTab {
  final String type;
  final String label;
  final Color color;
  final IconData icon;

  _ChartTab({
    required this.type,
    required this.label,
    required this.color,
    required this.icon,
  });
}
