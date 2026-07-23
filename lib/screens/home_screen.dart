import 'package:flutter/material.dart';
import '../services/air_quality_service.dart';
import '../utils/ica_calculator.dart';
import '../widgets/metric_card.dart';
import '../widgets/ica_gauge.dart';
import '../widgets/alert_banner.dart';

class HomeScreen extends StatelessWidget {
  final AirQualityService service;

  const HomeScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final data = service.current;
        final ica = service.currentAqi != null
            ? IcaCalculator.fromAqi(service.currentAqi!)
            : IcaCalculator.fromPm25(data.pm25);

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Monitor de Calidad del Aire',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Actualizado: ${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  if (service.isLoading)
                    const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(
                      service.usingRealData ? Icons.wifi : Icons.wifi_off,
                      size: 14,
                      color:
                          service.usingRealData ? Colors.green : Colors.orange,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    service.usingRealData
                        ? 'Datos reales (Open-Meteo)'
                        : 'Simulado (sin conexión)',
                    style: TextStyle(
                        fontSize: 11,
                        color: service.usingRealData
                            ? Colors.green
                            : Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (ica.value > AirQualityService.icaAlertThreshold)
                AlertBanner(ica: ica),
              IcaGauge(ica: ica),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  MetricCard(
                    label: 'CO',
                    value: data.co2.toStringAsFixed(0),
                    unit: 'µg/m³',
                    icon: Icons.cloud_outlined,
                    color: Colors.blueGrey,
                  ),
                  MetricCard(
                    label: 'PM2.5',
                    value: data.pm25.toStringAsFixed(1),
                    unit: 'µg/m³',
                    icon: Icons.grain,
                    color: Colors.deepPurple,
                  ),
                  MetricCard(
                    label: 'Temperatura',
                    value: data.temperature.toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: Colors.orange,
                  ),
                  MetricCard(
                    label: 'Humedad',
                    value: data.humidity.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.water_drop_outlined,
                    color: Colors.teal,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
