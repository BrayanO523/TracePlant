import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../widgets/lote_card.dart';
import 'ciclo_form_screen.dart';

class ProduccionLotesScreen extends ConsumerWidget {
  final String productoraId;
  final String fincaId;
  final String fincaNombre;

  const ProduccionLotesScreen({
    super.key,
    required this.productoraId,
    required this.fincaId,
    required this.fincaNombre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado general de lotes (ya implementado)
    final lotesState = ref.watch(lotesNotifierProvider(productoraId));

    // Filtramos localmente por finca
    final lotesDeFinca = lotesState.lotes
        .where((l) => l.fincaId == fincaId)
        .toList();

    // También escuchamos el estado de producción para saber el paso actual de cada lote
    ref.watch(produccionNotifierProvider(productoraId));

    return Scaffold(
      appBar: AppBar(title: Text('Lotes en $fincaNombre')),
      body: lotesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : lotesState.error != null
          ? Center(child: Text('Error: ${lotesState.error}'))
          : lotesDeFinca.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_free, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay lotes registrados en esta finca.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ve a Administración para crear lotes.',
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lotesDeFinca.length,
              itemBuilder: (context, index) {
                final lote = lotesDeFinca[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LoteCard(
                    lote: lote,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            final siguiente = ref
                                .read(produccionNotifierProvider(productoraId))
                                .siguientePaso(lote.id);

                            return CicloFormScreen(
                              productoraId: productoraId,
                              idLote: lote.id,
                              nombreLote: lote.nombre,
                              areaLote: lote.area,
                              variedadLote: lote.variedad,
                              siguientePaso: siguiente,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
