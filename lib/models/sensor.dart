class Sensor {
  final String id;
  final String type; // 'temperature', 'air_humidity', 'soil_moisture'
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;

  Sensor({
    required this.id,
    required this.type,
    required this.value,
    this.minValue = 0,
    this.maxValue = 100,
    this.unit = '%',
  });

  double get percentage => ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

  Sensor copyWith({
    String? id,
    String? type,
    double? value,
    double? minValue,
    double? maxValue,
    String? unit,
  }) {
    return Sensor(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      unit: unit ?? this.unit,
    );
  }
}
