import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/air_quality_service.dart';
import '../models/monitoring_station.dart';
import '../utils/ica_calculator.dart';

/// Mapa interactivo con todas las estaciones de monitoreo.
/// Usa flutter_map + OpenStreetMap (sin necesidad de API key de Google),
/// lo que lo hace fácil de correr directamente dentro de FlutLab.
class MapScreen extends StatelessWidget {
  final AirQualityService service;

  const MapScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final stations = service.stations;
        final center = stations.isNotEmpty
            ? LatLng(stations.first.lat, stations.first.lng)
            : const LatLng(7.0653, -73.8547); // Barrancabermeja por defecto

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Estaciones de Monitoreo',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.air_quality_monitor',
                    ),
                    MarkerLayer(
                      markers: stations.map((s) {
                        final ica = service.currentAqi != null
                            ? IcaCalculator.fromAqi(service.currentAqi!)
                            : IcaCalculator.fromPm25(s.lastReading.pm25);
                        return Marker(
                          point: LatLng(s.lat, s.lng),
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            onTap: () => _showStationSheet(context, s),
                            child: Container(
                              decoration: BoxDecoration(
                                color: ica.color,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4)
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${ica.value}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStationSheet(BuildContext context, MonitoringStation s) {
    final ica = service.currentAqi != null
        ? IcaCalculator.fromAqi(service.currentAqi!)
        : IcaCalculator.fromPm25(s.lastReading.pm25);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('ICA: ${ica.value} · ${ica.category}',
                  style:
                      TextStyle(color: ica.color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _statRow('CO', '${s.lastReading.co2.toStringAsFixed(0)} µg/m³'),
              _statRow(
                  'PM2.5', '${s.lastReading.pm25.toStringAsFixed(1)} µg/m³'),
              _statRow('Temperatura',
                  '${s.lastReading.temperature.toStringAsFixed(1)} °C'),
              _statRow(
                  'Humedad', '${s.lastReading.humidity.toStringAsFixed(0)} %'),
              if (!service.usingRealData) ...[
                const SizedBox(height: 10),
                const Text(
                    '⚠ Sin conexión a Open-Meteo — mostrando datos simulados.',
                    style: TextStyle(fontSize: 11, color: Colors.orange)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
