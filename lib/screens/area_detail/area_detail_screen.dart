import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/common/delete_area_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sensor_bar.dart';
import '../../widgets/device_tile.dart';
import '../../widgets/sensor_chart.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/add_device_dialog.dart';
import '../../widgets/device/timer_picker_dialog.dart';

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

    // Sensor chart will handle its own real-time stream via areaId
    // final sensorHistory = garden.getSensorHistory(areaId);

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

      // 24h Chart section
      SensorChartCard(
        areaId: areaId,
      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

      // Device control section
      AppCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        l10n.t('device_control'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (ctx) => const AddDeviceDialog(),
                          );
                          if (result != null) {
                            garden.addDevice(areaId, result['name'], result['type']);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        color: AppColors.primaryGreen,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
                  onDelete: () => _confirmDeleteDevice(context, garden, device.id),
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
          IconButton(
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
          const SizedBox(width: 8),
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
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            content[0], // Mode
                            const SizedBox(height: 16),
                            content[1], // Sensor data
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            content[2], // Chart
                            const SizedBox(height: 16),
                            content[3], // Device control
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  content[0],
                  const SizedBox(height: 12),
                  content[1],
                  const SizedBox(height: 12),
                  content[2],
                  const SizedBox(height: 12),
                  content[3],
                ],
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

  void _confirmDeleteArea(BuildContext context, GardenProvider garden) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteAreaDialog(
        areaName: garden.getArea(areaId)?.name ?? '',
        onConfirm: () {
          garden.deleteArea(areaId);
          context.pop(); // Quay lại trang chủ
        },
      ),
    );
  }

  void _confirmDeleteDevice(BuildContext context, GardenProvider garden, String deviceId) {
    _showConfirmDialog(
      context,
      title: 'Xóa thiết bị?',
      message: 'Xác nhận xóa thiết bị này khỏi khu vực?',
      onConfirm: () {
        garden.deleteDevice(areaId, deviceId);
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
