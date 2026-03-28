/// Configuration for a garden area's automatic control thresholds.
/// Designed for Firebase Realtime Database:
///   zones/{zoneId}/configs/soil_moisture_threshold
///   zones/{zoneId}/configs/max_temperature
///   zones/{zoneId}/configs/light_on_hour
///   zones/{zoneId}/configs/light_on_minute
///   zones/{zoneId}/configs/light_off_hour
///   zones/{zoneId}/configs/light_off_minute
class AreaConfig {
  /// Min soil moisture % — pump activates when value drops below this
  final double soilMoistureThreshold;

  /// Max temperature °C — fan/mist activates when value exceeds this
  final double maxTemperature;

  /// Lighting schedule: hour to turn lights ON (0-23)
  final int lightOnHour;
  final int lightOnMinute;

  /// Lighting schedule: hour to turn lights OFF (0-23)
  final int lightOffHour;
  final int lightOffMinute;

  const AreaConfig({
    this.soilMoistureThreshold = 40.0,
    this.maxTemperature = 32.0,
    this.lightOnHour = 18,
    this.lightOnMinute = 0,
    this.lightOffHour = 22,
    this.lightOffMinute = 0,
  });

  AreaConfig copyWith({
    double? soilMoistureThreshold,
    double? maxTemperature,
    int? lightOnHour,
    int? lightOnMinute,
    int? lightOffHour,
    int? lightOffMinute,
  }) {
    return AreaConfig(
      soilMoistureThreshold:
          soilMoistureThreshold ?? this.soilMoistureThreshold,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      lightOnHour: lightOnHour ?? this.lightOnHour,
      lightOnMinute: lightOnMinute ?? this.lightOnMinute,
      lightOffHour: lightOffHour ?? this.lightOffHour,
      lightOffMinute: lightOffMinute ?? this.lightOffMinute,
    );
  }

  /// Serialize to Firebase Realtime Database map.
  Map<String, dynamic> toMap() {
    return {
      'soil_moisture_threshold': soilMoistureThreshold,
      'max_temperature': maxTemperature,
      'light_on_hour': lightOnHour,
      'light_on_minute': lightOnMinute,
      'light_off_hour': lightOffHour,
      'light_off_minute': lightOffMinute,
    };
  }

  /// Deserialize from Firebase snapshot.
  factory AreaConfig.fromMap(Map<String, dynamic> map) {
    return AreaConfig(
      soilMoistureThreshold:
          (map['soil_moisture_threshold'] as num?)?.toDouble() ?? 40.0,
      maxTemperature:
          (map['max_temperature'] as num?)?.toDouble() ?? 32.0,
      lightOnHour: (map['light_on_hour'] as int?) ?? 18,
      lightOnMinute: (map['light_on_minute'] as int?) ?? 0,
      lightOffHour: (map['light_off_hour'] as int?) ?? 22,
      lightOffMinute: (map['light_off_minute'] as int?) ?? 0,
    );
  }

  String get lightOnLabel =>
      '${lightOnHour.toString().padLeft(2, '0')}:${lightOnMinute.toString().padLeft(2, '0')}';

  String get lightOffLabel =>
      '${lightOffHour.toString().padLeft(2, '0')}:${lightOffMinute.toString().padLeft(2, '0')}';
}
