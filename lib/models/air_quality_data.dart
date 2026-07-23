/// Representa una lectura puntual de los sensores en un instante de tiempo.
class AirQualityData {
  final double co2; // ppm
  final double pm25; // µg/m3
  final double temperature; // °C
  final double humidity; // %
  final DateTime timestamp;

  AirQualityData({
    required this.co2,
    required this.pm25,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  AirQualityData copyWith({
    double? co2,
    double? pm25,
    double? temperature,
    double? humidity,
    DateTime? timestamp,
  }) {
    return AirQualityData(
      co2: co2 ?? this.co2,
      pm25: pm25 ?? this.pm25,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
