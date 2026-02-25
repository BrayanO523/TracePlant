import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/entities/ciclo_produccion.dart';
import '../../../domain/entities/produccion_enums.dart';
import '../viewmodels/consultas_notifier.dart';

class ConsultasCiclosActivosScreen extends ConsumerWidget {
  final String productoraId;

  const ConsultasCiclosActivosScreen({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultasProvider(productoraId));

    // Filtrar localmente en base a lo que ya descargó el Notifier
    final ciclosActivos =
        state.ciclos
            .where(
              (c) =>
                  c.estado == EstadoCiclo.sembrado ||
                  c.estado == EstadoCiclo.encintado,
            )
            .toList()
          ..sort((a, b) => b.fechaSiembra.compareTo(a.fechaSiembra));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Ciclos Activos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ciclosActivos.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: ciclosActivos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ciclo = ciclosActivos[index];
                return _CicloActivoCard(ciclo: ciclo);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.loop_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Sin ciclos activos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos los lotes están libres o cosechados',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _CicloActivoCard extends StatelessWidget {
  final CicloProduccion ciclo;

  const _CicloActivoCard({required this.ciclo});

  @override
  Widget build(BuildContext context) {
    final bool esEncintado = ciclo.estado == EstadoCiclo.encintado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Lote: ${ciclo.nombreLote}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (esEncintado
                              ? AppColors.estadoEncintado
                              : AppColors.estadoSembrado)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ciclo.estado.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: esEncintado
                        ? AppColors.estadoEncintado
                        : AppColors.estadoSembrado,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _InfoItem(
                icon: Icons.grass_rounded,
                label: 'Variedad',
                value: ciclo.variedad,
              ),
              const SizedBox(width: 16),
              _InfoItem(
                icon: Icons.calendar_month_rounded,
                label: 'Semanas',
                value:
                    '${DateTime.now().difference(ciclo.fechaSiembra).inDays ~/ 7}',
              ),
              const SizedBox(width: 16),
              if (esEncintado &&
                  (!ciclo.esCultivoContinuo || ciclo.totalEncintado > 0))
                _InfoItem(
                  icon: Icons.loyalty_rounded,
                  label: 'Encintado',
                  value: '${ciclo.totalEncintado.toInt()}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
