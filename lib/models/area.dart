import 'sensor.dart';
import 'device.dart';
import 'area_config.dart';
import 'automation_rule.dart';

class Area {
  final String id;
  String name;
  bool isAutoMode;
  final List<Sensor> sensors;
  final List<Device> devices;
  final List<AutomationRule> rules;
  AreaConfig config;
  DateTime? createdAt;

  Area({
    required this.id,
    required this.name,
    this.isAutoMode = true,
    required this.sensors,
    required this.devices,
    this.rules = const [],
    AreaConfig? config,
    this.createdAt,
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
    List<Sensor>? sensors,
    List<Device>? devices,
    List<AutomationRule>? rules,
    AreaConfig? config,
    DateTime? createdAt,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      sensors: sensors ?? this.sensors,
      devices: devices ?? this.devices,
      rules: rules ?? this.rules,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  factory Area.fromMap(String id, Map<String, dynamic> map) {
    return Area(
      id: id,
      name: map['name'] as String? ?? 'Chưa đặt tên',
      isAutoMode: map['isAutoMode'] as bool? ?? true,
      config: map['config'] != null 
          ? AreaConfig.fromMap(map['config'] as Map<String, dynamic>)
          : const AreaConfig(),
      rules: (map['rules'] as List? ?? [])
          .map((r) => AutomationRule.fromMap(r['id'] ?? '', r as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt())
          : null,
      sensors: (map['sensors'] as List<dynamic>?)
              ?.map((s) => Sensor.fromMap(s['id'] ?? '', s as Map<String, dynamic>))
              .toList() ??
          [],
      devices: (map['devices'] as List<dynamic>?)
              ?.map((d) => Device.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isAutoMode': isAutoMode,
      'config': config.toMap(),
      'createdAt': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'sensors': sensors.map((s) => s.toMap()..addAll({'id': s.id})).toList(),
      'devices': devices.map((d) => d.toMap()).toList(),
      'rules': rules.map((r) => r.toMap()).toList(),
    };
  }
}
