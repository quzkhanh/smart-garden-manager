import 'sensor.dart';
import 'device.dart';
import 'area_config.dart';

class Area {
  final String id;
  String name;
  bool isAutoMode;
  final List<Sensor> sensors;
  final List<Device> devices;
  AreaConfig config;

  Area({
    required this.id,
    required this.name,
    this.isAutoMode = true,
    required this.sensors,
    required this.devices,
    AreaConfig? config,
  }) : config = config ?? const AreaConfig();

  Sensor? getSensor(String type) {
    try {
      return sensors.firstWhere((s) => s.type == type);
    } catch (_) {
      return null;
    }
  }

  int get activeDeviceCount => devices.where((d) => d.isOn).length;

  Area copyWith({
    String? id,
    String? name,
    bool? isAutoMode,
    List<Sensor>? sensors,
    List<Device>? devices,
    AreaConfig? config,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      sensors: sensors ?? this.sensors,
      devices: devices ?? this.devices,
      config: config ?? this.config,
    );
  }
}
