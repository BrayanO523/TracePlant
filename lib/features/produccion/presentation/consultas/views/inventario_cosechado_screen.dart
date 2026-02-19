import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/di/providers.dart';
import '../../../domain/entities/ciclo_produccion.dart';
import '../../widgets/ciclo_timeline.dart';
import '../viewmodels/consultas_notifier.dart';

class InventarioCosechadoScreen extends ConsumerWidget {
  final String productoraId;

  const InventarioCosechadoScreen({super.key, required this.productoraId});

  void _showCicloTimeline(BuildContext context, dynamic ciclo) {
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
    final state = ref.watch(consultasProvider(productoraId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Inventario Cosechado',
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
                    color: AppColors.estadoEntregado.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.estadoEntregado,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pendiente de Entrega',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.inventario.length} lotes \u00b7 ${state.totalInventario.toStringAsFixed(0)} unidades',
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
            child: state.inventario.isEmpty
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
                          'Sin cosechas pendientes de entrega',
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
                    itemCount: state.inventario.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ciclo = state.inventario[index];
                      return InventarioCard(
                        ciclo: ciclo,
                        productoraId: productoraId,
                        onTap: () => _showCicloTimeline(context, ciclo),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card de inventario cosechado con botón de entrega.
class InventarioCard extends ConsumerWidget {
  final CicloProduccion ciclo;
  final String productoraId;
  final VoidCallback onTap;

  const InventarioCard({
    super.key,
    required this.ciclo,
    required this.productoraId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = ciclo.fechaCosecha != null
        ? '${ciclo.fechaCosecha!.day}/${ciclo.fechaCosecha!.month}/${ciclo.fechaCosecha!.year}'
        : 'Sin fecha';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                          ciclo.nombreLote,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${ciclo.variedad} \u00b7 ${DateTime.now().difference(ciclo.fechaSiembra).inDays} d\u00edas',
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
                        ciclo.cantidadCosecha?.toStringAsFixed(0) ?? "0",
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
              const SizedBox(height: 12),
              // Botón entregar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar Entrega'),
                        content: Text(
                          '\u00bfMarcar ${ciclo.nombreLote} como entregado a empacadora?\n\nCantidad: ${ciclo.cantidadCosecha?.toStringAsFixed(0) ?? "0"}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Entregar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      final authState = ref.read(authStateStreamProvider);
                      final uid = authState.asData?.value?.uid ?? 'unknown';
                      final notifier = ref.read(
                        produccionNotifierProvider(productoraId).notifier,
                      );
                      final ok = await notifier.registrarEntrega(
                        idCiclo: ciclo.id,
                        uidUsuario: uid,
                      );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Entrega registrada exitosamente'),
                            backgroundColor: AppColors.estadoEntregado,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.local_shipping_rounded, size: 18),
                  label: const Text('Marcar Entregado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.estadoEntregado,
                    side: const BorderSide(color: AppColors.estadoEntregado),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
