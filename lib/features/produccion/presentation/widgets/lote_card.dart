import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/produccion_enums.dart';
import '../../../../core/utils/formatters.dart';

/// Card de lote rediseñada para LISTA (Compacta/Horizontal).
/// Maximiza el espacio y muestra la información clave en una fila.
class LoteCard extends StatelessWidget {
  final Lote lote;
  final VoidCallback? onTap;

  const LoteCard({super.key, required this.lote, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOcupado = lote.estado == EstadoLote.ocupado;
    final statusColor = isOcupado
        ? AppColors.estadoSembrado
        : AppColors.estadoCosechado; // Verde para disponible

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 8), // Margen inferior para lista
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. Icono de Estado (Izquierda)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOcupado ? Icons.grass_rounded : Icons.check_circle_outline,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // 2. Info Principal (Centro)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lote.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.formatNumber(lote.area)} mz • ${lote.variedad}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Status Badge + Chevron (Derecha)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(
                    text: isOcupado ? 'Sembrado' : 'Disponible',
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
