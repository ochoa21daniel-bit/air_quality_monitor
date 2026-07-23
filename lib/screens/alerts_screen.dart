import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/air_quality_service.dart';

/// Historial de alertas disparadas cuando el ICA supera el umbral definido.
class AlertsScreen extends StatelessWidget {
  final AirQualityService service;

  const AlertsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final alerts = service.alerts;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertas de Contaminación',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: alerts.isEmpty
                      ? const Center(
                          child: Text('Sin alertas registradas todavía'))
                      : ListView.separated(
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final a = alerts[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: a.ica.color,
                                child: Text('${a.ica.value}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ),
                              title:
                                  Text('${a.stationName} · ${a.ica.category}'),
                              subtitle: Text(a.ica.advice),
                              trailing: Text(fmt.format(a.timestamp),
                                  style:
                                      const TextStyle(color: Colors.black45)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
