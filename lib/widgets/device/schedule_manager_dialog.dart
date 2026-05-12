import 'package:flutter/material.dart';
import '../../models/area.dart';
import '../../models/watering_schedule.dart';
import '../../providers/garden_provider.dart';
import '../../theme/app_colors.dart';
import '../common/app_card.dart';

class ScheduleManagerDialog extends StatelessWidget {
  final Area area;
  final GardenProvider garden;

  const ScheduleManagerDialog({
    super.key,
    required this.area,
    required this.garden,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedules = area.schedules;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý lịch tưới',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (schedules.isEmpty)
            _buildEmptyState(theme)
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return _buildScheduleItem(context, theme, schedule);
                },
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddScheduleDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm lịch mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.timer_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có lịch tưới nào được thiết lập',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, ThemeData theme, WateringSchedule schedule) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop_rounded, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.deviceName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${schedule.hour.toString().padLeft(2, '0')}:${schedule.minute.toString().padLeft(2, '0')} • ${schedule.durationMinutes} phút',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  _formatDays(schedule.daysOfWeek),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => garden.deleteWateringSchedule(area.id, schedule.id),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Hàng ngày';
    final List<String> labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days.map((d) => labels[d - 1]).join(', ');
  }

  void _showAddScheduleDialog(BuildContext context) {
    // We'll call the existing _showScheduleDialog logic or a refactored version
    // For now, let's keep it simple and just close this and call the parent's
    Navigator.pop(context, 'add');
  }
}
