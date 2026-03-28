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
}
