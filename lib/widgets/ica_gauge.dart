import 'package:flutter/material.dart';
import '../utils/ica_calculator.dart';

/// Medidor circular del Índice de Calidad del Aire.
class IcaGauge extends StatelessWidget {
  final IcaResult ica;

  const IcaGauge({super.key, required this.ica});

  @override
  Widget build(BuildContext context) {
    final progress = (ica.value / 500).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 9,
                    backgroundColor: ica.color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(ica.color),
                  ),
                ),
                Text('${ica.value}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Índice de Calidad del Aire',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(ica.category,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ica.color)),
                const SizedBox(height: 4),
                Text(ica.advice,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
