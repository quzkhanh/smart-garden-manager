import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/garden_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sensor_bar.dart';
import '../../widgets/device_tile.dart';
import '../../widgets/sensor_chart.dart';
import '../../widgets/common/app_card.dart';
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

    final content = [
      // Soil Renovation banner (when active)
      if (area.isSoilRenovation)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                Colors.deepOrange.withValues(alpha: isDark ? 0.15 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.construction, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang cải tạo đất',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tất cả thiết bị đã tắt. Chế độ thủ công.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _confirmStopRenovation(context, garden),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Kết thúc'),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

      // Offline banner
      if (!area.isOnline)
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
                Colors.redAccent.withValues(alpha: isDark ? 0.15 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mất kết nối (Ngoại tuyến)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thiết bị điều khiển vườn không phản hồi. Dữ liệu có thể đã cũ.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

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
                    area.isSoilRenovation
                        ? 'Cải tạo đất'
                        : area.isAutoMode
                            ? l10n.t('auto_mode')
                            : l10n.t('manual_mode'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: area.isSoilRenovation
                          ? Colors.orange
                          : area.isAutoMode
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
                      onChanged: area.isSoilRenovation
                          ? null
                          : (_) => garden.toggleAreaMode(areaId),
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

      SensorChartCard(
        areaId: areaId,
      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

      // Area Notes section
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ghi chú khu vực',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.edit3, size: 18),
                  onPressed: () => _showNotesDialog(context, garden, area.notes),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (area.notes.isEmpty)
              Text(
                'Chưa có ghi chú nào. Hãy thêm ghi chú về cây trồng hoặc lịch trình canh tác.',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              )
            else
              Text(
                area.notes,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

      // Device control section (no add/delete - devices are fixed hardware)
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
                if (area.isSoilRenovation)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cải tạo đất',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (area.isAutoMode)
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
                  isAutoMode: area.isAutoMode || area.isSoilRenovation,
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
            child: const Icon(LucideIcons.chevronLeft, size: 22),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Soil renovation toggle button
          IconButton(
            tooltip: area.isSoilRenovation ? 'Kết thúc cải tạo đất' : 'Cải tạo đất',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: area.isSoilRenovation
                    ? Colors.orange.withValues(alpha: isDark ? 0.3 : 0.15)
                    : Colors.orange.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.construction,
                size: 20,
                color: area.isSoilRenovation ? Colors.orange : Colors.orange.shade300,
              ),
            ),
            onPressed: () {
              if (area.isSoilRenovation) {
                _confirmStopRenovation(context, garden);
              } else {
                _confirmStartRenovation(context, garden);
              }
            },
          ),
          IconButton(
            tooltip: l10n.t('area_config'),
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.slidersHorizontal,
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
                          children: content.asMap().entries
                              .where((e) => [0, 1, 2, 3].contains(_getContentRole(e.key, area.isSoilRenovation, area.isOnline)))
                              .expand((e) => [e.value, const SizedBox(height: 16)])
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          children: content.asMap().entries
                              .where((e) => [4, 5, 6].contains(_getContentRole(e.key, area.isSoilRenovation, area.isOnline)))
                              .expand((e) => [e.value, const SizedBox(height: 16)])
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: content.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => content[index],
              ),
      ),
    );
  }

  /// Map content index to a role for wide layout distribution.
  /// Roles: 0=renovation banner, 1=offline banner, 2=mode toggle, 3=sensor data,
  ///        4=chart, 5=notes, 6=device control
  int _getContentRole(int index, bool isSoilRenovation, bool isOnline) {
    int i = 0;
    if (isSoilRenovation) {
      if (index == i) return 0; // renovation banner
      i++;
    }
    if (!isOnline) {
      if (index == i) return 1; // offline banner
      i++;
    }
    // Fixed order: mode(2), sensor(3), chart(4), notes(5), device(6)
    final fixedRoles = [2, 3, 4, 5, 6];
    final offset = index - i;
    if (offset >= 0 && offset < fixedRoles.length) return fixedRoles[offset];
    return -1;
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

  void _showNotesDialog(BuildContext context, GardenProvider garden, String currentNotes) {
    final controller = TextEditingController(text: currentNotes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ghi chú khu vực'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú (ví dụ: gieo hạt ngày 10/5, bón phân...)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              garden.updateAreaNotes(areaId, controller.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmStartRenovation(BuildContext context, GardenProvider garden) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.construction, color: Colors.orange.shade600),
            const SizedBox(width: 10),
            const Text('Cải tạo đất?'),
          ],
        ),
        content: const Text(
          'Khi vào chế độ cải tạo đất, tất cả thiết bị sẽ bị TẮT và khu vực chuyển sang chế độ THỦ CÔNG.\n\nBạn sẽ không thể bật thiết bị cho đến khi kết thúc cải tạo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              garden.toggleSoilRenovation(areaId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _confirmStopRenovation(BuildContext context, GardenProvider garden) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kết thúc cải tạo đất?'),
        content: const Text(
          'Khu vực sẽ trở lại chế độ thủ công. Bạn có thể chuyển sang tự động sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              garden.toggleSoilRenovation(areaId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
  }
}
