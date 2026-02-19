import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';

import '../../../../administracion/domain/entities/finca.dart';
import '../../../domain/entities/lote.dart';
import '../../widgets/cohorte_card.dart'; // Import nuevo
import '../../views/selectors/selector_filter_modal.dart';
import '../viewmodels/consultas_notifier.dart'; // Import recuperado

class ProyeccionCosechaScreen extends ConsumerWidget {
  final String productoraId;

  const ProyeccionCosechaScreen({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultasProvider(productoraId));
    // Usamos la nueva lista de cohortes
    final cohortes = state.cohortes;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Proyección de Cosecha',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              // Preparar datos para filtro
              final variedades = state.lotes
                  .map((l) => l.variedad)
                  .where((v) => v.isNotEmpty)
                  .toSet()
                  .toList();
              final fincas = state.fincas.map((f) => f.nombre).toSet().toList();
              // Cintas: extraer de datos o hardcode? Mejor de la distribucion actual si es posible,
              // o pasarlo vacio si no es critico, o extraer de ciclos.
              // El state tiene inputs? state.ciclos tiene todo.
              final cintas = state.ciclos
                  .expand((c) => c.encintados.map((e) => e.cintaNombre))
                  .toSet()
                  .toList();

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SelectorFilterModal(
                  variedades: variedades,
                  cintas: cintas,
                  fincas: fincas,
                  sortAscending: state.sortAscending,
                  startDate: state.fechaInicio,
                  endDate: state.fechaFin,
                  variedad: state.variedadFilter,
                  cinta: state.cintaFilter,
                  finca: state.fincaFilter,
                  onApply:
                      ({
                        required sortAscending,
                        startDate,
                        endDate,
                        variedad,
                        cinta,
                        finca,
                      }) {
                        ref
                            .read(consultasProvider(productoraId).notifier)
                            .setFilters(
                              sortAscending: sortAscending,
                              startDate: startDate,
                              endDate: endDate,
                              variedadFilter: variedad,
                              cintaFilter: cinta,
                              fincaFilter: finca,
                            );
                      },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Informativo
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Proyección Semanal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${cohortes.length} grupos programados · ${state.semanasParaCosecha} sem config.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de Cohortes
          Expanded(
            child: cohortes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin proyección futura',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay encintados activos para proyectar',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cohortes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cohortes[index];
                      // Resolver Finca y Lote
                      final lote = state.lotes.cast<Lote>().firstWhere(
                        (l) => l.id == item.loteId,
                        orElse: () => const Lote(
                          id: '',
                          nombre: 'Desconocido',
                          fincaId: '',
                          idProductora: '',
                          area: 0,
                          variedad: 'Desconocida',
                        ),
                      );
                      final finca = state.fincas.cast<Finca>().firstWhere(
                        (f) => f.id == lote.fincaId,
                        orElse: () => const Finca(
                          id: '',
                          nombre: '',
                          productoraId: '',
                          ubicacion: '',
                          areaTotal: 0,
                        ),
                      );

                      return CohorteCard(
                        cohorte: item,
                        fincaNombre: finca.nombre,
                        loteNombre: lote.nombre,
                        onTap: () {
                          // Futuro: Ver desglose por lote al tocar la cohorte
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
