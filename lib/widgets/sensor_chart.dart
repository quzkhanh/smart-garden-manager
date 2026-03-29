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
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
          // Toggle Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final t = tabs[index];
                final isSelected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 16, color: isSelected ? t.color : Colors.grey.shade600),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            t.label, 
                            style: TextStyle(
                              color: t.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            )
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                    selectedColor: t.color.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? t.color.withValues(alpha: 0.4) : Colors.transparent,
                      )
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Swipable Charts
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: tabs.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _buildChart(tabs[index]);
              },
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
