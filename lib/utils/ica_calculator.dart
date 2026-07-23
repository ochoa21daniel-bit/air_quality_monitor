import 'package:flutter/material.dart';

/// Categoría del Índice de Calidad del Aire (ICA / AQI) calculado a partir
/// del PM2.5, usando los puntos de corte simplificados de la EPA.
class IcaResult {
  final int value; // Valor ICA (0-500)
  final String category; // Etiqueta en español
  final Color color; // Color representativo
  final String advice; // Recomendación corta

  IcaResult({
    required this.value,
    required this.category,
    required this.color,
    required this.advice,
  });
}

class IcaCalculator {
  // Puntos de corte oficiales EPA para PM2.5 (µg/m3) -> rango ICA
  static const List<List<double>> _breakpoints = [
    [0.0, 12.0, 0, 50],
    [12.1, 35.4, 51, 100],
    [35.5, 55.4, 101, 150],
    [55.5, 150.4, 151, 200],
    [150.5, 250.4, 201, 300],
    [250.5, 500.4, 301, 500],
  ];

  /// Construye el resultado a partir de un valor de AQI (US EPA) ya calculado
  /// por una fuente externa (ej. Open-Meteo), en vez de derivarlo nosotros
  /// mismos del PM2.5. Usa las mismas categorías/colores que fromPm25.
  static IcaResult fromAqi(int value) {
    if (value <= 50) {
      return IcaResult(
          value: value,
          category: 'Buena',
          color: const Color(0xFF4CAF50),
          advice: 'Calidad del aire satisfactoria.');
    } else if (value <= 100) {
      return IcaResult(
          value: value,
          category: 'Moderada',
          color: const Color(0xFFFFEB3B),
          advice: 'Aceptable para la mayoría de las personas.');
    } else if (value <= 150) {
      return IcaResult(
          value: value,
          category: 'Dañina (grupos sensibles)',
          color: const Color(0xFFFF9800),
          advice:
              'Grupos sensibles deben reducir esfuerzo prolongado al aire libre.');
    } else if (value <= 200) {
      return IcaResult(
          value: value,
          category: 'Dañina',
          color: const Color(0xFFF44336),
          advice: 'Todos pueden empezar a experimentar efectos en la salud.');
    } else if (value <= 300) {
      return IcaResult(
          value: value,
          category: 'Muy dañina',
          color: const Color(0xFF9C27B0),
          advice: 'Alerta sanitaria: evitar actividades al aire libre.');
    } else {
      return IcaResult(
          value: value,
          category: 'Peligrosa',
          color: const Color(0xFF7E0023),
          advice: 'Emergencia sanitaria. Permanecer en interiores.');
    }
  }

  static IcaResult fromPm25(double pm25) {
    final clamped = pm25.clamp(0.0, 500.4);
    List<double> bp = _breakpoints.last;
    for (final b in _breakpoints) {
      if (clamped >= b[0] && clamped <= b[1]) {
        bp = b;
        break;
      }
    }
    final cLow = bp[0], cHigh = bp[1], iLow = bp[2], iHigh = bp[3];
    final ica = ((iHigh - iLow) / (cHigh - cLow)) * (clamped - cLow) + iLow;
    final value = ica.round();

    if (value <= 50) {
      return IcaResult(
        value: value,
        category: 'Buena',
        color: const Color(0xFF4CAF50),
        advice: 'Calidad del aire satisfactoria.',
      );
    } else if (value <= 100) {
      return IcaResult(
        value: value,
        category: 'Moderada',
        color: const Color(0xFFFFEB3B),
        advice: 'Aceptable para la mayoría de las personas.',
      );
    } else if (value <= 150) {
      return IcaResult(
        value: value,
        category: 'Dañina (grupos sensibles)',
        color: const Color(0xFFFF9800),
        advice:
            'Grupos sensibles deben reducir esfuerzo prolongado al aire libre.',
      );
    } else if (value <= 200) {
      return IcaResult(
        value: value,
        category: 'Dañina',
        color: const Color(0xFFF44336),
        advice: 'Todos pueden empezar a experimentar efectos en la salud.',
      );
    } else if (value <= 300) {
      return IcaResult(
        value: value,
        category: 'Muy dañina',
        color: const Color(0xFF9C27B0),
        advice: 'Alerta sanitaria: evitar actividades al aire libre.',
      );
    } else {
      return IcaResult(
        value: value,
        category: 'Peligrosa',
        color: const Color(0xFF7E0023),
        advice: 'Emergencia sanitaria. Permanecer en interiores.',
      );
    }
  }
}
