class WateringSchedule {
  final String id;
  final String deviceId;
  final String deviceName;
  final int hour;
  final int minute;
  final int durationMinutes;
  final List<int> daysOfWeek; // 1 (Mon) to 7 (Sun)
  bool isEnabled;

  WateringSchedule({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'hour': hour,
      'minute': minute,
      'durationMinutes': durationMinutes,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }

  factory WateringSchedule.fromMap(Map<String, dynamic> map) {
    return WateringSchedule(
      id: map['id'] as String? ?? '',
      deviceId: map['deviceId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      hour: (map['hour'] as num?)?.toInt() ?? 0,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  WateringSchedule copyWith({
    String? id,
    String? deviceId,
    String? deviceName,
    int? hour,
    int? minute,
    int? durationMinutes,
    List<int>? daysOfWeek,
    bool? isEnabled,
  }) {
    return WateringSchedule(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
