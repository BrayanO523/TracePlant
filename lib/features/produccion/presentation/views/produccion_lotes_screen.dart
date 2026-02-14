import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/lote_card.dart';
import 'ciclo_form_screen.dart';
import 'ciclo_history_screen.dart';

class ProduccionLotesScreen extends ConsumerWidget {
  final String productoraId;
  final String fincaId;
  final String fincaNombre;
  final bool readOnly;

  const ProduccionLotesScreen({
    super.key,
    required this.productoraId,
    required this.fincaId,
    required this.fincaNombre,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesState = ref.watch(lotesNotifierProvider(productoraId));

    final lotesDeFinca = lotesState.lotes
        .where((l) => l.fincaId == fincaId)
        .toList();

    ref.watch(produccionNotifierProvider(productoraId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Lotes en $fincaNombre'), centerTitle: true),
      body: lotesState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : lotesState.error != null
          ? Center(
              child: Text(
                'Error: ${lotesState.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            )
          : lotesDeFinca.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_off_rounded,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay lotes registrados en esta finca.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ve a Administración para crear lotes.',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint),
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
                      if (readOnly) {
                        final produccionState = ref.read(
                          produccionNotifierProvider(productoraId),
                        );
                        final ciclosLote = produccionState.ciclos
                            .where((c) => c.idLote == lote.id)
                            .toList();

                        if (ciclosLote.isNotEmpty) {
                          final cicloAMostrar = ciclosLote.first;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CicloHistoryScreen(ciclo: cicloAMostrar),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'No hay historial de ciclos para este lote',
                              ),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              final siguiente = ref
                                  .read(
                                    produccionNotifierProvider(productoraId),
                                  )
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
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
