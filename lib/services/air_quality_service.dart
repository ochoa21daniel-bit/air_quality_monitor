import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/air_quality_data.dart';
import '../models/monitoring_station.dart';
import '../utils/ica_calculator.dart';
import 'open_meteo_client.dart';

/// Registro de una alerta disparada cuando el ICA supera un umbral.
class AlertEvent {
  final DateTime timestamp;
  final String stationName;
  final IcaResult ica;

  AlertEvent({
    required this.timestamp,
    required this.stationName,
    required this.ica,
  });
}

/// Servicio central de la app.
///
/// Ahora consume datos REALES de la API pública y gratuita Open-Meteo
/// (air-quality-api.open-meteo.com), sin necesidad de API key. Esa API
/// da PM2.5, CO, temperatura, humedad y el AQI (US EPA) ya calculado,
/// estimados con el modelo atmosférico CAMS para cualquier coordenada
/// del mundo — incluida Barrancabermeja, que no tiene estación física
/// registrada en redes abiertas como OpenAQ.
///
/// Si la petición falla (sin internet, o corriendo offline en FlutLab),
/// cae automáticamente a un generador simulado para que la app nunca
/// se quede sin datos que mostrar (bandera `usingRealData`).
///
/// --------------------------------------------------------------------
/// PARA CONECTAR TU ESP32 (MQTT/HiveMQ) EN VEZ DE Open-Meteo:
/// Sustituye `_fetchReal()` por una suscripción MQTT y llama a
/// `_pushReading(...)` con los valores que publique tu sensor. El resto
/// de la app (ICA, gráficas, mapa, alertas) no necesita cambios.
/// --------------------------------------------------------------------
class AirQualityService extends ChangeNotifier {
  AirQualityService({this.lat = 7.0653, this.lng = -73.8547}) {
    _seedStations();
    _init();
  }

  final double lat;
  final double lng;
  final Random _rng = Random();
  Timer? _timer;

  bool isLoading = true;
  bool usingRealData = false;
  String? errorMessage;

  // Última lectura y AQI oficial (US EPA) calculado por Open-Meteo.
  AirQualityData current = AirQualityData(
    co2: 0,
    pm25: 0,
    temperature: 0,
    humidity: 0,
    timestamp: DateTime.now(),
  );
  int? currentAqi; // null hasta que llegue el primer dato real

  // Histórico para las gráficas (real si hay conexión, simulado si no).
  final List<AirQualityData> history = [];
  static const int maxHistory = 30;

  // Estaciones para el mapa (mismo dato de ciudad aplicado a cada pin,
  // ver nota en README sobre resolución del modelo).
  final List<MonitoringStation> stations = [];

  // Log de alertas.
  final List<AlertEvent> alerts = [];
  static const int icaAlertThreshold = 100;

  Future<void> _init() async {
    await _fetchReal();
    // Open-Meteo actualiza su modelo cada hora; 10 min es más que suficiente
    // para reflejar cambios sin saturar la API gratuita.
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => _fetchReal());
  }

  void _seedStations() {
    final defs = [
      {'id': 'st1', 'name': 'Estación Centro', 'lat': 7.0653, 'lng': -73.8547},
      {
        'id': 'st2',
        'name': 'Estación Ciudadela Café Madrid',
        'lat': 7.0810,
        'lng': -73.8600
      },
      {
        'id': 'st3',
        'name': 'Estación Refinería (Ecopetrol)',
        'lat': 7.0450,
        'lng': -73.8650
      },
      {
        'id': 'st4',
        'name': 'Estación Provivienda',
        'lat': 7.0700,
        'lng': -73.8450
      },
      {
        'id': 'st5',
        'name': 'Estación El Campín',
        'lat': 7.0580,
        'lng': -73.8570
      },
    ];
    for (final d in defs) {
      stations.add(MonitoringStation(
        id: d['id'] as String,
        name: d['name'] as String,
        lat: d['lat'] as double,
        lng: d['lng'] as double,
        lastReading: current,
      ));
    }
  }

  Future<void> _fetchReal() async {
    try {
      final hourly =
          await OpenMeteoClient.fetchHourlyHistory(lat: lat, lng: lng);
      if (hourly.isEmpty) throw Exception('Sin datos');

      history
        ..clear()
        ..addAll(hourly.length > maxHistory
            ? hourly.sublist(hourly.length - maxHistory)
            : hourly);

      current = history.last;
      currentAqi = await OpenMeteoClient.fetchLatestAqi(lat: lat, lng: lng);

      // Todas las estaciones reflejan el mismo dato de ciudad: Open-Meteo
      // usa un modelo de ~45km de resolución para esta zona, no hay
      // granularidad real por barrio.
      for (final s in stations) {
        s.lastReading = current;
      }

      final ica = IcaCalculator.fromAqi(
          currentAqi ?? IcaCalculator.fromPm25(current.pm25).value);
      _maybeAlert('Barrancabermeja (modelo Open-Meteo)', ica);

      usingRealData = true;
      errorMessage = null;
    } catch (e) {
      // Sin internet o la API no respondió: usamos simulación de respaldo
      // para que la app siga siendo demostrable.
      usingRealData = false;
      errorMessage =
          'No se pudo conectar a Open-Meteo. Mostrando datos simulados.';
      if (history.isEmpty) _seedSimulatedHistory();
      _simulateTick();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _seedSimulatedHistory() {
    final now = DateTime.now();
    for (int i = maxHistory; i > 0; i--) {
      history.add(_randomReading(at: now.subtract(Duration(minutes: i * 2))));
    }
    current = history.last;
  }

  AirQualityData _randomReading({DateTime? at}) {
    return AirQualityData(
      co2: 100 + _rng.nextDouble() * 300, // CO simulado en µg/m3
      pm25: 5 + _rng.nextDouble() * 120,
      temperature: 24 + _rng.nextDouble() * 8,
      humidity: 50 + _rng.nextDouble() * 35,
      timestamp: at ?? DateTime.now(),
    );
  }

  void _simulateTick() {
    final next = AirQualityData(
      co2: (current.co2 + (_rng.nextDouble() - 0.5) * 40).clamp(50, 800),
      pm25: (current.pm25 + (_rng.nextDouble() - 0.5) * 20).clamp(2, 300),
      temperature:
          (current.temperature + (_rng.nextDouble() - 0.5) * 1.2).clamp(15, 35),
      humidity:
          (current.humidity + (_rng.nextDouble() - 0.5) * 6).clamp(20, 95),
      timestamp: DateTime.now(),
    );
    current = next;
    history.add(next);
    if (history.length > maxHistory) history.removeAt(0);
    for (final s in stations) {
      s.lastReading = next;
    }
    final ica = IcaCalculator.fromPm25(next.pm25);
    _maybeAlert('Simulación (sin conexión)', ica);
  }

  void _maybeAlert(String stationName, IcaResult ica) {
    if (ica.value > icaAlertThreshold) {
      if (alerts.isNotEmpty &&
          alerts.first.stationName == stationName &&
          alerts.first.ica.value == ica.value) {
        return; // evita duplicar la misma alerta en cada refresco
      }
      alerts.insert(
          0,
          AlertEvent(
              timestamp: DateTime.now(), stationName: stationName, ica: ica));
      if (alerts.length > 50) alerts.removeLast();
    }
  }

  /// Fuerza un refresco manual (ej. pull-to-refresh o botón).
  Future<void> refreshNow() => _fetchReal();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
