import 'sensor.dart';
import 'device.dart';
import 'area_config.dart';
import 'automation_rule.dart';
import 'watering_schedule.dart';

class Area {
  final String id;
  String name;
  bool isAutoMode;
  bool isSoilRenovation;
  String notes;
  final List<Sensor> sensors;
  final List<Device> devices;
  final List<AutomationRule> rules;
  final List<WateringSchedule> schedules;
  AreaConfig config;
  DateTime? createdAt;
  DateTime? lastSeen;

  Area({
    required this.id,
    required this.name,
    this.isAutoMode = true,
    this.isSoilRenovation = false,
    this.notes = '',
    required this.sensors,
    required this.devices,
    this.rules = const [],
    this.schedules = const [],
    AreaConfig? config,
    this.createdAt,
    this.lastSeen,
  }) : config = config ?? const AreaConfig();

  Sensor? getSensor(String type) {
    try {
      return sensors.firstWhere((s) => s.type == type);
    } catch (_) {
      return null;
    }
  }

  int get activeDeviceCount => devices.where((d) => d.isOn).length;
  int get totalDeviceCount => devices.length;

  Area copyWith({
    String? id,
    String? name,
    bool? isAutoMode,
    bool? isSoilRenovation,
    String? notes,
    List<Sensor>? sensors,
    List<Device>? devices,
    List<AutomationRule>? rules,
    List<WateringSchedule>? schedules,
    AreaConfig? config,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      isSoilRenovation: isSoilRenovation ?? this.isSoilRenovation,
      notes: notes ?? this.notes,
      sensors: sensors ?? this.sensors,
      devices: devices ?? this.devices,
      rules: rules ?? this.rules,
      schedules: schedules ?? this.schedules,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  bool get isOnline {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen!).inMinutes < 5;
  }

  factory Area.fromMap(String id, Map<String, dynamic> map) {
    final filteredDevices = (map['devices'] as List<dynamic>?)
            ?.map((d) => Device.fromMap(d as Map<String, dynamic>))
            .where((d) => d.type != 'light')
            .toList() ??
        [];

    return Area(
      id: id,
      name: map['name'] as String? ?? 'Chưa đặt tên',
      isAutoMode: map['isAutoMode'] as bool? ?? true,
      isSoilRenovation: map['isSoilRenovation'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
      config: map['config'] != null 
          ? AreaConfig.fromMap(map['config'] as Map<String, dynamic>)
          : const AreaConfig(),
      sensors: (map['sensors'] as List<dynamic>?)
              ?.map((s) => Sensor.fromMap(s['id'] ?? '', s as Map<String, dynamic>))
              .toList() ??
          [],
      devices: filteredDevices,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt())
          : null,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['lastSeen'] as num).toInt())
          : null,
      rules: (map['rules'] as List? ?? [])
          .map((r) => AutomationRule.fromMap(r['id'] ?? '', r as Map<String, dynamic>))
          .where((rule) => rule.actions.every((a) => filteredDevices.any((d) => d.id == a.deviceId)))
          .toList(),
      schedules: (map['schedules'] as List? ?? [])
          .map((s) => WateringSchedule.fromMap(s as Map<String, dynamic>))
          .where((s) => filteredDevices.any((d) => d.id == s.deviceId))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isAutoMode': isAutoMode,
      'isSoilRenovation': isSoilRenovation,
      'notes': notes,
      'config': config.toMap(),
      'createdAt': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'sensors': sensors.map((s) => s.toMap()..addAll({'id': s.id})).toList(),
      'devices': devices.map((d) => d.toMap()).toList(),
      'rules': rules.map((r) => r.toMap()).toList(),
      'schedules': schedules.map((s) => s.toMap()).toList(),
    };
  }
}
