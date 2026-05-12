/// Represents a controllable device in a garden area.
/// Designed for easy Firebase Firestore serialization.
class Device {
  final String id;
  final String name;
  final String type; // 'pump', 'mist', 'fan', 'valve'
  bool isOn;

  /// Timer fields for manual mode scheduling.
  /// [timerDuration] is the total duration set by user.
  /// [timerEndTime] is when the device should auto-toggle.
  /// When timerEndTime passes, the device toggles off (or on).
  Duration? timerDuration;
  DateTime? timerEndTime;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.isOn = false,
    this.timerDuration,
    this.timerEndTime,
  });

  /// Whether a timer is currently active
  bool get hasActiveTimer =>
      timerEndTime != null && timerEndTime!.isAfter(DateTime.now());

  /// Remaining time on the timer
  Duration get timerRemaining {
    if (timerEndTime == null) return Duration.zero;
    final remaining = timerEndTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Clear the timer
  void clearTimer() {
    timerDuration = null;
    timerEndTime = null;
  }

  /// Set a timer for specified duration
  void setTimer(Duration duration) {
    timerDuration = duration;
    timerEndTime = DateTime.now().add(duration);
  }

  Device copyWith({
    String? id,
    String? name,
    String? type,
    bool? isOn,
    Duration? timerDuration,
    DateTime? timerEndTime,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isOn: isOn ?? this.isOn,
      timerDuration: timerDuration ?? this.timerDuration,
      timerEndTime: timerEndTime ?? this.timerEndTime,
    );
  }

  /// Create from Firestore document
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id']?.toString() ?? 'dev_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Unnamed Device',
      type: map['type']?.toString() ?? 'other',
      isOn: map['isOn'] as bool? ?? false,
      timerEndTime: map['timerEndTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['timerEndTime'] as num).toInt())
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isOn': isOn,
      'timerEndTime': timerEndTime?.millisecondsSinceEpoch,
    };
  }
}
