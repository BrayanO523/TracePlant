import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:productoraempacadora/features/administracion/presentation/providers/admin_view_model.dart';
import '../../domain/entities/finca.dart';
import '../providers/administracion_provider.dart';
import 'forms/lote_form_screen.dart';

class FincaDetailScreen extends ConsumerWidget {
  final Finca finca;

  const FincaDetailScreen({super.key, required this.finca});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesByFincaStreamProvider(finca.id));

    return Scaffold(
      appBar: AppBar(title: Text(finca.nombre)),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoTile('Ubicación', finca.ubicacion),
                _InfoTile('Area Total', '${finca.areaTotal} m²'),
              ],
            ),
          ),

          // Lotes List
          Expanded(
            child: lotesAsync.when(
              data: (lotes) {
                if (lotes.isEmpty)
                  return const Center(child: Text('No hay lotes registrados.'));

                final currentArea = lotes.fold(
                  0.0,
                  (sum, lote) => sum + lote.area,
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Total Agregado: ${currentArea.toStringAsFixed(2)} m²',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.separated(
                        itemCount: lotes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final lote = lotes[index];
                          return ListTile(
                            leading: const Icon(Icons.grid_on),
                            title: Text(lote.nombre),
                            subtitle: Text('${lote.area} m²'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoteFormScreen(
                                        finca: finca,
                                        lote: lote,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteLote(context, ref, lote.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoteFormScreen(finca: finca)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteLote(BuildContext context, WidgetRef ref, String loteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Eliminar este Lote? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(adminViewModelProvider.notifier)
                  .deleteLote(loteId, finca.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
