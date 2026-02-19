import 'package:flutter/material.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../widgets/ciclo_timeline.dart';

class CicloHistoryScreen extends StatelessWidget {
  final CicloProduccion ciclo;

  const CicloHistoryScreen({super.key, required this.ciclo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial del Ciclo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Linea de tiempo de eventos para ${ciclo.nombreLote}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CicloTimeline(ciclo: ciclo),
          ],
        ),
      ),
    );
  }
}
