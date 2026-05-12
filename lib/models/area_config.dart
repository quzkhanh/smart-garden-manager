/// Configuration for a garden area's automatic control thresholds.
/// Designed for Firebase Realtime Database:
///   zones/{zoneId}/configs/soil_moisture_threshold
///   zones/{zoneId}/configs/max_temperature
class AreaConfig {
  /// Min soil moisture % — pump activates when value drops below this
  final double soilMoistureThreshold;

  /// Max temperature °C — fan/mist activates when value exceeds this
  final double maxTemperature;

  const AreaConfig({
    this.soilMoistureThreshold = 40.0,
    this.maxTemperature = 32.0,
  });

  AreaConfig copyWith({
    double? soilMoistureThreshold,
    double? maxTemperature,
  }) {
    return AreaConfig(
      soilMoistureThreshold:
          soilMoistureThreshold ?? this.soilMoistureThreshold,
      maxTemperature: maxTemperature ?? this.maxTemperature,
    );
  }

  /// Serialize to Firebase Realtime Database map.
  Map<String, dynamic> toMap() {
    return {
      'soil_moisture_threshold': soilMoistureThreshold,
      'max_temperature': maxTemperature,
    };
  }

  /// Deserialize from Firebase snapshot.
  factory AreaConfig.fromMap(Map<String, dynamic> map) {
    return AreaConfig(
      soilMoistureThreshold:
          (map['soil_moisture_threshold'] as num?)?.toDouble() ?? 40.0,
      maxTemperature:
          (map['max_temperature'] as num?)?.toDouble() ?? 32.0,
    );
  }
}
