import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/garden_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sensor_bar.dart';
import '../../widgets/device_tile.dart';
import '../../widgets/sensor_chart.dart';
import '../../widgets/common/app_card.dart';

class AreaDetailScreen extends StatelessWidget {
  final String areaId;

  const AreaDetailScreen({super.key, required this.areaId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final area = garden.getArea(areaId);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    if (area == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Area not found')),
      );
    }

    // Get chart data
    final sensorHistory = garden.getSensorHistory(areaId);

    final content = [
      // Mode toggle section
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('operation_mode'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    area.isAutoMode
                        ? l10n.t('auto_mode')
                        : l10n.t('manual_mode'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: area.isAutoMode
                          ? AppColors.primaryGreen
                          : AppColors.alertMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.t('manual_mode'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: !area.isAutoMode
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: !area.isAutoMode
                            ? AppColors.alertMedium
                            : null,
                      ),
                    ),
                    Switch.adaptive(
                      value: area.isAutoMode,
                      onChanged: (_) => garden.toggleAreaMode(areaId),
                      activeTrackColor: AppColors.primaryGreen,
                    ),
                    Text(
                      l10n.t('auto_mode'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: area.isAutoMode
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: area.isAutoMode
                            ? AppColors.primaryGreen
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 4),

      // Sensor data section
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('sensor_data'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...area.sensors.map((sensor) => SensorBar(
                  type: sensor.type,
                  value: sensor.value,
                  unit: sensor.unit,
                  percentage: sensor.percentage,
                )),
          ],
        ),
      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
      const SizedBox(height: 4),

      // 24h Chart section
      SensorChartCard(
        history: sensorHistory,
      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
      const SizedBox(height: 4),

      // Device control section
      AppCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.t('device_control'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (area.isAutoMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.t('auto_mode'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...area.devices.map((device) => DeviceTile(
                  device: device,
                  isAutoMode: area.isAutoMode,
                  onToggle: (_) => garden.toggleDevice(areaId, device.id),
                  onTimerTap: () => _showTimerDialog(context, garden, device.id),
                  onCancelTimer: () =>
                      garden.cancelDeviceTimer(areaId, device.id),
                )),
          ],
        ),
      ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(area.name, style: theme.textTheme.titleLarge),
            Text(
              l10n.t('area_detail'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: l10n.t('area_config'),
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
              ),
              onPressed: () => context.push('/area/${areaId}/config'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isWide
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            content[0], content[1], content[2],
                            content[3], content[4],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [content[5], content[6]],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: content,
              ),
      ),
    );
  }

  void _showTimerDialog(
      BuildContext context, GardenProvider garden, String deviceId) async {
    final duration = await showDialog<Duration>(
      context: context,
      builder: (context) => const TimerPickerDialog(),
    );
    if (duration != null) {
      garden.setDeviceTimer(areaId, deviceId, duration);
    }
  }
}
