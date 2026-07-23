import 'package:flutter/material.dart';
import '../utils/ica_calculator.dart';

/// Banner de alerta visible en el dashboard cuando el ICA supera el umbral.
class AlertBanner extends StatelessWidget {
  final IcaResult ica;

  const AlertBanner({super.key, required this.ica});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ica.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ica.color),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: ica.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Alerta: calidad del aire "${ica.category}". ${ica.advice}',
              style: TextStyle(
                  color: ica.color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
