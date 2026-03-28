import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_reading.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/garden_provider.dart';
import 'chart/sensor_chart_base.dart';

/// A card that displays a tabbed view of all 3 sensor charts (24h history).
/// Connects to GardenProvider to fetch real-time streams from Firestore.
class SensorChartCard extends StatefulWidget {
  final String areaId;

  const SensorChartCard({super.key, required this.areaId});

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
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(l10n.t('chart_24h'), style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
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
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              labelPadding: EdgeInsets.zero,
              tabs: tabs.map((t) => Tab(
                height: 34,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 14),
                    const SizedBox(width: 4),
                    Flexible(child: Text(t.label, overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
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
    final garden = context.read<GardenProvider>();

    return StreamBuilder<List<SensorReading>>(
      stream: garden.getSensorHistoryStream(widget.areaId, tab.type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = snapshot.data ?? [];

        if (readings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 32, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(
                  'Chưa có dữ liệu lịch sử',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        double minY, maxY;
        String unit;
        switch (tab.type) {
          case 'temperature': minY = 0; maxY = 50; unit = '°C'; break;
          case 'air_humidity': minY = 0; maxY = 100; unit = '%'; break;
          case 'soil_moisture': minY = 0; maxY = 100; unit = '%'; break;
          default: minY = 0; maxY = 100; unit = '';
        }

        return SensorChart(
          sensorType: tab.type,
          readings: readings,
          unit: unit,
          minY: minY,
          maxY: maxY,
        );
      },
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
