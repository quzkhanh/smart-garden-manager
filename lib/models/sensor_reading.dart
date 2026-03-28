/// A single sensor reading at a point in time.
/// Designed for easy Firebase Firestore serialization.
class SensorReading {
  final DateTime timestamp;
  final double value;

  SensorReading({
    required this.timestamp,
    required this.value,
  });

  /// Create from Firestore document
  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      value: (map['value'] as num).toDouble(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'value': value,
    };
  }
}

/// Holds 24h history data for all sensor types in an area.
/// Each list contains readings sorted by timestamp ascending.
class SensorHistory {
  final String areaId;
  final List<SensorReading> temperatureReadings;
  final List<SensorReading> airHumidityReadings;
  final List<SensorReading> soilMoistureReadings;

  SensorHistory({
    required this.areaId,
    required this.temperatureReadings,
    required this.airHumidityReadings,
    required this.soilMoistureReadings,
  });

  /// Get readings by sensor type key
  List<SensorReading> getReadings(String type) {
    switch (type) {
      case 'temperature':
        return temperatureReadings;
      case 'air_humidity':
        return airHumidityReadings;
      case 'soil_moisture':
        return soilMoistureReadings;
      default:
        return [];
    }
  }
}
