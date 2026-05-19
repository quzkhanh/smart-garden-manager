import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/activity_log_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final uid = auth.uid;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
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
          onPressed: () => context.pop(),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : StreamBuilder<QuerySnapshot>(
              stream: ActivityLogService.getLogsStream(uid, limit: 100),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có hoạt động nào',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group logs by date
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;
                  // Fallback to now() for local pending writes (timestamp is null temporarily)
                  final date = timestamp?.toDate() ?? DateTime.now();
                  final dateKey = DateFormat('dd/MM/yyyy').format(date);
                  grouped.putIfAbsent(dateKey, () => []);
                  grouped[dateKey]!.add(doc);
                }

                final sortedKeys = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, groupIndex) {
                    final dateKey = sortedKeys[groupIndex];
                    final logs = grouped[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isToday(dateKey) ? 'Hôm nay' : dateKey,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Divider(
                                  color: theme.dividerColor.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Log items
                        ...logs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final type = data['type'] as String? ?? '';
                          final description = data['description'] as String? ?? '';
                          final actorName = data['actorName'] as String? ?? 'Hệ thống';
                          final timestamp = data['timestamp'] as Timestamp?;
                          final date = timestamp?.toDate() ?? DateTime.now();
                          final timeStr = DateFormat('HH:mm').format(date);

                          return AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Emoji icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(type).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    ActivityLogService.getEmoji(type),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        description,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 12,
                                            color: theme.textTheme.bodySmall?.color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            actorName,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            timeStr,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms);
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  bool _isToday(String dateKey) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return dateKey == today;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'deviceToggle':
        return Colors.blue;
      case 'memberAdd':
        return Colors.green;
      case 'memberRemove':
        return Colors.red;
      case 'areaAdd':
        return AppColors.primaryGreen;
      case 'areaDelete':
        return Colors.red;
      case 'systemAuto':
        return Colors.orange;
      case 'modeChange':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
