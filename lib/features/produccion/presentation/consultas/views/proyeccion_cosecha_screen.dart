import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';

import '../../widgets/ciclo_timeline.dart';
import '../viewmodels/consultas_notifier.dart';

class ProyeccionCosechaScreen extends ConsumerWidget {
  final String productoraId;

  const ProyeccionCosechaScreen({super.key, required this.productoraId});

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
                    color: AppColors.accent.withOpacity(0.1),
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
                        'Próximas Cosechas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.proximasCosechas.length} lotes · ${state.semanasParaCosecha} sem config.',
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
            child: state.proximasCosechas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin cosechas proyectadas',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay ciclos encintados activos',
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
                    itemCount: state.proximasCosechas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = state.proximasCosechas[index];
                      return ProyeccionCard(
                        proyeccion: p,
                        onTap: () => _showCicloTimeline(context, p.ciclo),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card individual de proyección de cosecha.
class ProyeccionCard extends StatelessWidget {
  final ProximaCosechaLocal proyeccion;
  final VoidCallback onTap;

  const ProyeccionCard({
    super.key,
    required this.proyeccion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dias = proyeccion.diasRestantes;
    final ciclo = proyeccion.ciclo;

    // Determinar urgencia
    final IconData urgencyIcon;
    final String urgencyLabel;
    final Color urgencyBg;
    final Color urgencyFg;

    if (dias < 0) {
      urgencyIcon = Icons.warning_amber_rounded;
      urgencyLabel = 'Vencido ${-dias}d';
      urgencyBg = const Color(0xFFFFF0F0);
      urgencyFg = const Color(0xFFD32F2F);
    } else if (dias <= 14) {
      urgencyIcon = Icons.schedule_rounded;
      urgencyLabel = '$dias días';
      urgencyBg = const Color(0xFFFFF8E1);
      urgencyFg = const Color(0xFFE65100);
    } else {
      urgencyIcon = Icons.hourglass_bottom_rounded;
      urgencyLabel = '$dias días';
      urgencyBg = const Color(0xFFF0F4F8);
      urgencyFg = const Color(0xFF546E7A);
    }

    final fechaStr =
        '${proyeccion.fechaProyectada.day}/${proyeccion.fechaProyectada.month}/${proyeccion.fechaProyectada.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono de calendario
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info del lote
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ciclo.nombreLote,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ciclo.variedad} · ${ciclo.totalEncintado.toStringAsFixed(0)} uds',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Est: $fechaStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge de urgencia
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: urgencyBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(urgencyIcon, size: 14, color: urgencyFg),
                    const SizedBox(width: 4),
                    Text(
                      urgencyLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: urgencyFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
