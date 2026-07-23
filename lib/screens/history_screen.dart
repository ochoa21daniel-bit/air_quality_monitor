import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/air_quality_service.dart';

enum _Metric { co2, pm25, temperature, humidity }

/// Pantalla de gráficas históricas. Permite alternar entre las 4 métricas.
class HistoryScreen extends StatefulWidget {
  final AirQualityService service;

  const HistoryScreen({super.key, required this.service});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Metric _selected = _Metric.pm25;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.service,
      builder: (context, _) {
        final history = widget.service.history;
        final spots = <FlSpot>[];
        for (int i = 0; i < history.length; i++) {
          spots.add(FlSpot(i.toDouble(), _valueFor(history[i])));
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _Metric.values.map((m) {
                    return ChoiceChip(
                      label: Text(_labelFor(m)),
                      selected: _selected == m,
                      onSelected: (_) => setState(() => _selected = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: spots.isEmpty
                      ? const Center(
                          child: Text('Aún no hay datos suficientes'))
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(
                                show: true, drawVerticalLine: false),
                            titlesData: const FlTitlesData(
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: _colorFor(_selected),
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: _colorFor(_selected).withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _valueFor(data) {
    switch (_selected) {
      case _Metric.co2:
        return data.co2;
      case _Metric.pm25:
        return data.pm25;
      case _Metric.temperature:
        return data.temperature;
      case _Metric.humidity:
        return data.humidity;
    }
  }

  String _labelFor(_Metric m) {
    switch (m) {
      case _Metric.co2:
        return 'CO';
      case _Metric.pm25:
        return 'PM2.5';
      case _Metric.temperature:
        return 'Temperatura';
      case _Metric.humidity:
        return 'Humedad';
    }
  }

  Color _colorFor(_Metric m) {
    switch (m) {
      case _Metric.co2:
        return Colors.blueGrey;
      case _Metric.pm25:
        return Colors.deepPurple;
      case _Metric.temperature:
        return Colors.orange;
      case _Metric.humidity:
        return Colors.teal;
    }
  }
}
