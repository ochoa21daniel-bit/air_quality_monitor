import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_data.dart';

/// Cliente para la API pública y gratuita de Open-Meteo (sin API key).
///
/// Combina dos endpoints:
/// - air-quality-api.open-meteo.com  → PM2.5, PM10, CO, AQI (modelo CAMS)
/// - api.open-meteo.com              → temperatura y humedad
///
/// Nota importante: Open-Meteo estima estos valores con un modelo
/// atmosférico (no con una estación física en Barrancabermeja, que no
/// tiene ninguna registrada en redes abiertas). Es la mejor fuente
/// pública real disponible para esta ciudad, pero es una estimación de
/// modelo, no una medición puntual de sensor.
class OpenMeteoClient {
  static const _airQualityBase =
      'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const _weatherBase = 'https://api.open-meteo.com/v1/forecast';

  /// Devuelve el histórico horario (últimas ~24h reales + pronóstico corto)
  /// y el AQI (US EPA) por cada punto, ya calculado por Open-Meteo.
  static Future<List<AirQualityData>> fetchHourlyHistory({
    required double lat,
    required double lng,
  }) async {
    final airUri = Uri.parse(
      '$_airQualityBase?latitude=$lat&longitude=$lng'
      '&hourly=pm2_5,carbon_monoxide,us_aqi'
      '&past_days=1&forecast_days=1&timezone=auto',
    );
    final weatherUri = Uri.parse(
      '$_weatherBase?latitude=$lat&longitude=$lng'
      '&hourly=temperature_2m,relative_humidity_2m'
      '&past_days=1&forecast_days=1&timezone=auto',
    );

    final responses = await Future.wait([
      http.get(airUri),
      http.get(weatherUri),
    ]);

    if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
      throw Exception('Open-Meteo respondió con error');
    }

    final airJson = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final weatherJson = jsonDecode(responses[1].body) as Map<String, dynamic>;

    final times = List<String>.from(airJson['hourly']['time']);
    final pm25 = List<num>.from(airJson['hourly']['pm2_5'].map((e) => e ?? 0));
    final co =
        List<num>.from(airJson['hourly']['carbon_monoxide'].map((e) => e ?? 0));
    final aqi = List<num>.from(airJson['hourly']['us_aqi'].map((e) => e ?? 0));
    final temp = List<num>.from(
        weatherJson['hourly']['temperature_2m'].map((e) => e ?? 0));
    final hum = List<num>.from(
        weatherJson['hourly']['relative_humidity_2m'].map((e) => e ?? 0));

    final result = <AirQualityData>[];
    for (int i = 0; i < times.length; i++) {
      result.add(AirQualityData(
        co2: co[i]
            .toDouble(), // en realidad es CO (monóxido) — ver nota en la UI
        pm25: pm25[i].toDouble(),
        temperature: temp[i].toDouble(),
        humidity: hum[i].toDouble(),
        timestamp: DateTime.parse(times[i]),
      ));
    }
    return result;
  }

  /// Extrae el AQI (US EPA) ya calculado, correspondiente al mismo índice
  /// horario que la última lectura devuelta por fetchHourlyHistory.
  static Future<int> fetchLatestAqi(
      {required double lat, required double lng}) async {
    final uri = Uri.parse(
      '$_airQualityBase?latitude=$lat&longitude=$lng&current=us_aqi',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200)
      throw Exception('Open-Meteo respondió con error');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final value = json['current']?['us_aqi'];
    return (value as num?)?.round() ?? 0;
  }
}
