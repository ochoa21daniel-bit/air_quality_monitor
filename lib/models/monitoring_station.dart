import 'air_quality_data.dart';

/// Representa una estación de monitoreo fija ubicada en el mapa.
class MonitoringStation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  AirQualityData lastReading;

  MonitoringStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.lastReading,
  });
}
