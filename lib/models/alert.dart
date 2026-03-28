enum AlertSeverity { high, medium, low }

class Alert {
  final String id;
  final String areaName;
  final String message;
  final DateTime time;
  final AlertSeverity severity;
  bool isRead;

  Alert({
    required this.id,
    required this.areaName,
    required this.message,
    required this.time,
    required this.severity,
    this.isRead = false,
  });

  Alert copyWith({
    String? id,
    String? areaName,
    String? message,
    DateTime? time,
    AlertSeverity? severity,
    bool? isRead,
  }) {
    return Alert(
      id: id ?? this.id,
      areaName: areaName ?? this.areaName,
      message: message ?? this.message,
      time: time ?? this.time,
      severity: severity ?? this.severity,
      isRead: isRead ?? this.isRead,
    );
  }

  factory Alert.fromMap(String id, Map<String, dynamic> map) {
    return Alert(
      id: id,
      areaName: map['areaName'] as String? ?? 'Vườn',
      message: map['message'] as String? ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == (map['severity'] as String?),
        orElse: () => AlertSeverity.medium,
      ),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'areaName': areaName,
      'message': message,
      'time': time.millisecondsSinceEpoch,
      'severity': severity.name,
      'isRead': isRead,
    };
  }
}
