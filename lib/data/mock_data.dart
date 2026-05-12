import 'dart:math';
import '../models/area.dart';
import '../models/device.dart';
import '../models/sensor.dart';
import '../models/alert.dart';
import '../models/logged_device.dart';
import '../models/sensor_reading.dart';

class MockData {
  MockData._();

  static List<Area> getAreas() {
    return [
      Area(
        id: 'area_1',
        name: 'Khu vực A',
        isAutoMode: true,
        sensors: [
          Sensor(id: 's1_1', type: 'temperature', value: 28, minValue: 0, maxValue: 50, unit: '°C'),
          Sensor(id: 's1_2', type: 'air_humidity', value: 65, minValue: 0, maxValue: 100, unit: '%'),
          Sensor(id: 's1_3', type: 'soil_moisture', value: 45, minValue: 0, maxValue: 100, unit: '%'),
        ],
        devices: [
          Device(id: 'd1_1', name: 'Bơm nước', type: 'pump', isOn: false),
          Device(id: 'd1_2', name: 'Phun sương', type: 'mist', isOn: true),
          Device(id: 'd1_3', name: 'Quạt thông gió', type: 'fan', isOn: true),
        ],
      ),
      Area(
        id: 'area_2',
        name: 'Khu vực B',
        isAutoMode: false,
        sensors: [
          Sensor(id: 's2_1', type: 'temperature', value: 32, minValue: 0, maxValue: 50, unit: '°C'),
          Sensor(id: 's2_2', type: 'air_humidity', value: 55, minValue: 0, maxValue: 100, unit: '%'),
          Sensor(id: 's2_3', type: 'soil_moisture', value: 30, minValue: 0, maxValue: 100, unit: '%'),
        ],
        devices: [
          Device(id: 'd2_1', name: 'Bơm nước', type: 'pump', isOn: true),
          Device(id: 'd2_2', name: 'Phun sương', type: 'mist', isOn: false),
          Device(id: 'd2_3', name: 'Quạt thông gió', type: 'fan', isOn: true),
        ],
      ),
      Area(
        id: 'area_3',
        name: 'Khu vực C',
        isAutoMode: true,
        sensors: [
          Sensor(id: 's3_1', type: 'temperature', value: 25, minValue: 0, maxValue: 50, unit: '°C'),
          Sensor(id: 's3_2', type: 'air_humidity', value: 72, minValue: 0, maxValue: 100, unit: '%'),
          Sensor(id: 's3_3', type: 'soil_moisture', value: 58, minValue: 0, maxValue: 100, unit: '%'),
        ],
        devices: [
          Device(id: 'd3_1', name: 'Bơm nước', type: 'pump', isOn: false),
          Device(id: 'd3_2', name: 'Van nước', type: 'valve', isOn: true),
        ],
      ),
      Area(
        id: 'area_4',
        name: 'Khu vực D',
        isAutoMode: false,
        sensors: [
          Sensor(id: 's4_1', type: 'temperature', value: 30, minValue: 0, maxValue: 50, unit: '°C'),
          Sensor(id: 's4_2', type: 'air_humidity', value: 48, minValue: 0, maxValue: 100, unit: '%'),
          Sensor(id: 's4_3', type: 'soil_moisture', value: 35, minValue: 0, maxValue: 100, unit: '%'),
        ],
        devices: [
          Device(id: 'd4_1', name: 'Bơm nước', type: 'pump', isOn: false),
          Device(id: 'd4_2', name: 'Phun sương', type: 'mist', isOn: false),
          Device(id: 'd4_3', name: 'Quạt thông gió', type: 'fan', isOn: false),
          Device(id: 'd4_5', name: 'Van nước', type: 'valve', isOn: false),
        ],
      ),
      Area(
        id: 'area_5',
        name: 'Khu vực E',
        isAutoMode: true,
        sensors: [
          Sensor(id: 's5_1', type: 'temperature', value: 27, minValue: 0, maxValue: 50, unit: '°C'),
          Sensor(id: 's5_2', type: 'air_humidity', value: 60, minValue: 0, maxValue: 100, unit: '%'),
          Sensor(id: 's5_3', type: 'soil_moisture', value: 50, minValue: 0, maxValue: 100, unit: '%'),
        ],
        devices: [
          Device(id: 'd5_1', name: 'Bơm nước', type: 'pump', isOn: true),
          Device(id: 'd5_2', name: 'Phun sương', type: 'mist', isOn: true),
        ],
      ),
    ];
  }

  static List<Alert> getAlerts() {
    final now = DateTime.now();
    return [
      Alert(
        id: 'alert_1',
        areaName: 'Khu vực B',
        message: 'Độ ẩm đất thấp - Cần tưới nước',
        time: now.subtract(const Duration(minutes: 42)),
        severity: AlertSeverity.high,
        isRead: false,
      ),
      Alert(
        id: 'alert_2',
        areaName: 'Khu vực A',
        message: 'Nhiệt độ cao hơn ngưỡng',
        time: now.subtract(const Duration(hours: 2)),
        severity: AlertSeverity.medium,
        isRead: false,
      ),
      Alert(
        id: 'alert_3',
        areaName: 'Khu vực C',
        message: 'Cảm biến hoạt động bình thường',
        time: now.subtract(const Duration(hours: 5)),
        severity: AlertSeverity.low,
        isRead: true,
      ),
      Alert(
        id: 'alert_4',
        areaName: 'Khu vực D',
        message: 'Bơm nước ngừng hoạt động bất thường',
        time: now.subtract(const Duration(hours: 8)),
        severity: AlertSeverity.high,
        isRead: true,
      ),
      Alert(
        id: 'alert_5',
        areaName: 'Khu vực E',
        message: 'Độ ẩm không khí thấp',
        time: now.subtract(const Duration(days: 1)),
        severity: AlertSeverity.medium,
        isRead: true,
      ),
      Alert(
        id: 'alert_6',
        areaName: 'Khu vực B',
        message: 'Quạt thông gió cần bảo trì',
        time: now.subtract(const Duration(days: 2)),
        severity: AlertSeverity.low,
        isRead: true,
      ),
    ];
  }

  static List<LoggedDevice> getLoggedDevices() {
    final now = DateTime.now();
    return [
      LoggedDevice(
        id: 'ld_1',
        name: 'iPhone 15 Pro',
        platform: 'mobile',
        lastActive: now.subtract(const Duration(minutes: 12)),
        isCurrentDevice: true,
        isOnline: true,
      ),
      LoggedDevice(
        id: 'ld_2',
        name: 'Chrome - MacBook Pro',
        platform: 'web',
        lastActive: now.subtract(const Duration(days: 1)),
        isCurrentDevice: false,
        isOnline: false,
      ),
      LoggedDevice(
        id: 'ld_3',
        name: 'iPad Air',
        platform: 'tablet',
        lastActive: now.subtract(const Duration(hours: 3)),
        isCurrentDevice: false,
        isOnline: false,
      ),
    ];
  }

  /// Generate 24h mock sensor history for a given area.
  /// In production, replace this with a Firebase Firestore query:
  /// ```dart
  /// FirebaseFirestore.instance
  ///   .collection('areas/$areaId/sensor_readings')
  ///   .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(hours: 24)))
  ///   .orderBy('timestamp')
  ///   .get()
  /// ```
  static SensorHistory getSensorHistory(String areaId) {
    final now = DateTime.now();
    final rng = Random(areaId.hashCode); // deterministic per area
    const dataPoints = 48; // every 30 min for 24h

    // Base values vary by area
    final tempBase = 25.0 + rng.nextDouble() * 8;
    final humidBase = 55.0 + rng.nextDouble() * 15;
    final soilBase = 40.0 + rng.nextDouble() * 20;

    List<SensorReading> generateReadings(
      double baseValue,
      double amplitude,
      double noiseRange,
      double minVal,
      double maxVal,
      double phaseShift,
    ) {
      return List.generate(dataPoints, (i) {
        final hoursAgo = 24.0 - (i * 24.0 / dataPoints);
        final timestamp = now.subtract(Duration(
          minutes: (hoursAgo * 60).round(),
        ));
        // Sine wave simulating day/night cycle + random noise
        final wave = sin((i / dataPoints) * 2 * pi + phaseShift) * amplitude;
        final noise = (rng.nextDouble() - 0.5) * noiseRange;
        final value = (baseValue + wave + noise).clamp(minVal, maxVal);
        return SensorReading(timestamp: timestamp, value: value);
      });
    }

    return SensorHistory(
      areaId: areaId,
      temperatureReadings: generateReadings(
        tempBase, 4.0, 1.5, 0, 50, 0,
      ),
      airHumidityReadings: generateReadings(
        humidBase, 10.0, 3.0, 0, 100, pi, // inverse of temp
      ),
      soilMoistureReadings: generateReadings(
        soilBase, 8.0, 2.0, 0, 100, pi / 2,
      ),
    );
  }
}
