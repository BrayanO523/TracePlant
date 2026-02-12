import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/production_fincas_notifier.dart';
import 'produccion_lotes_screen.dart';

class ProduccionFincasScreen extends ConsumerWidget {
  final String productoraId;

  const ProduccionFincasScreen({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productionFincasProvider(productoraId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Fincas')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(child: Text('Error: ${state.error}'))
          : state.fincas.isEmpty
          ? const Center(child: Text('No tienes fincas registradas.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.fincas.length,
              itemBuilder: (context, index) {
                final finca = state.fincas[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.terrain, color: Colors.white),
                    ),
                    title: Text(
                      finca.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${finca.ubicacion} • ${finca.areaTotal.toStringAsFixed(2)} mz',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProduccionLotesScreen(
                            productoraId: productoraId,
                            fincaId: finca.id,
                            fincaNombre: finca.nombre,
                          ),
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
