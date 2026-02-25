import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';

import '../../../domain/entities/ciclo_produccion.dart';
import '../../widgets/ciclo_timeline.dart';
import '../viewmodels/consultas_notifier.dart';
import '../../../../../core/utils/formatters.dart';

class CosechasPendientesScreen extends ConsumerWidget {
  final String productoraId;

  const CosechasPendientesScreen({super.key, required this.productoraId});

  void _showCicloTimeline(BuildContext context, CicloProduccion ciclo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: CicloTimeline(ciclo: ciclo),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchar solo información agregada y la lista de IDs (usando select)
    final totalPendientes = ref.watch(
      consultasProvider(
        productoraId,
      ).select((s) => s.cosechasPendientes.length),
    );
    final totalUnidades = ref.watch(
      consultasProvider(productoraId).select((s) => s.totalCosechasPendientes),
    );
    final idsPendientes = ref.watch(
      consultasProvider(
        productoraId,
      ).select((s) => s.cosechasPendientes.map((c) => c.id).toList()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Cosechado',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
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
                    color: AppColors.estadoCosechado.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.estadoCosechado,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lotes Cosechados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$totalPendientes lotes \u00b7 ${AppFormatters.formatInt(totalUnidades)} unidades',
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

          // Lista
          Expanded(
            child: idsPendientes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin cosechas registradas',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: idsPendientes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final idCiclo = idsPendientes[index];
                      return CosechaPendienteCard(
                        idCiclo: idCiclo,
                        productoraId: productoraId,
                        onShowTimeline: _showCicloTimeline,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card de cosecha pendiente aislada leyendo su estado con select
class CosechaPendienteCard extends ConsumerWidget {
  final String idCiclo;
  final String productoraId;
  final void Function(BuildContext, CicloProduccion) onShowTimeline;

  const CosechaPendienteCard({
    super.key,
    required this.idCiclo,
    required this.productoraId,
    required this.onShowTimeline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Select Inteligente: El widget individual solo se redibuja si ESTE ciclo experimenta algún cambio
    final cicloModel = ref.watch(
      consultasProvider(productoraId).select((state) {
        return state.cosechasPendientes.firstWhere((c) => c.id == idCiclo);
      }),
    );

    final dateStr = cicloModel.fechaCosecha != null
        ? '${cicloModel.fechaCosecha!.day}/${cicloModel.fechaCosecha!.month}/${cicloModel.fechaCosecha!.year}'
        : 'Sin fecha';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onShowTimeline(context, cicloModel),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: lote + variedad
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.estadoCosechado,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cicloModel.nombreLote,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${cicloModel.variedad} \u00b7 ${DateTime.now().difference(cicloModel.fechaSiembra).inDays} d\u00edas',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cantidad cosechada
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatInt(cicloModel.cantidadCosecha),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.estadoCosechado,
                        ),
                      ),
                      Text(
                        'Cosechado $dateStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
