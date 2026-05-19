import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Types of activity that can be logged
enum ActivityType {
  deviceToggle,    // Bật/tắt thiết bị
  memberAdd,       // Thêm thành viên
  memberRemove,    // Xóa thành viên
  areaAdd,         // Thêm khu vườn
  areaDelete,      // Xóa khu vườn
  configChange,    // Thay đổi cấu hình
  scheduleAdd,     // Thêm lịch tưới
  scheduleDelete,  // Xóa lịch tưới
  ruleAdd,         // Thêm rule tự động
  ruleDelete,      // Xóa rule tự động
  systemAuto,      // Hệ thống tự động thực hiện
  modeChange,      // Đổi chế độ (auto/manual)
  nameChange,      // Đổi tên hiển thị
}

class ActivityLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log an activity to Firestore
  static Future<void> log({
    required String uid,
    required ActivityType type,
    required String description,
    String? actorName,
    String? actorPhone,
    String? areaId,
    String? areaName,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activity_logs')
          .add({
        'type': type.name,
        'description': description,
        'actorName': actorName ?? 'Hệ thống',
        'actorPhone': actorPhone ?? '',
        'areaId': areaId ?? '',
        'areaName': areaName ?? '',
        'timestamp': Timestamp.now(),
        'extra': extra ?? {},
      });
    } catch (e) {
      debugPrint('Failed to log activity: $e');
    }
  }

  /// Get activity logs stream
  static Stream<QuerySnapshot> getLogsStream(String uid, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Delete all activity logs
  static Future<void> clearAllLogs(String uid) async {
    try {
      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('users')
          .doc(uid)
          .collection('activity_logs')
          .get();
      
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }

  /// Get icon for activity type
  static String getEmoji(String type) {
    switch (type) {
      case 'deviceToggle':
        return '🔌';
      case 'memberAdd':
        return '👤➕';
      case 'memberRemove':
        return '👤❌';
      case 'areaAdd':
        return '🌱';
      case 'areaDelete':
        return '🗑️';
      case 'configChange':
        return '⚙️';
      case 'scheduleAdd':
        return '📅➕';
      case 'scheduleDelete':
        return '📅❌';
      case 'ruleAdd':
        return '🤖➕';
      case 'ruleDelete':
        return '🤖❌';
      case 'systemAuto':
        return '🤖';
      case 'modeChange':
        return '🔄';
      case 'nameChange':
        return '✏️';
      default:
        return '📝';
    }
  }
}
