class LoggedDevice {
  final String id;
  String name;
  final String platform; // 'mobile', 'web', 'tablet'
  final DateTime lastActive;
  final bool isCurrentDevice;
  final bool isOnline;

  LoggedDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastActive,
    this.isCurrentDevice = false,
    this.isOnline = false,
  });

  LoggedDevice copyWith({
    String? id,
    String? name,
    String? platform,
    DateTime? lastActive,
    bool? isCurrentDevice,
    bool? isOnline,
  }) {
    return LoggedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      lastActive: lastActive ?? this.lastActive,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
