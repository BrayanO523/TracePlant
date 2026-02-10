import 'package:flutter/material.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';
import 'color_cinta_ext.dart';

/// Timeline visual premium para un ciclo de producción.
class CicloTimeline extends StatelessWidget {
  final CicloProduccion ciclo;

  const CicloTimeline({super.key, required this.ciclo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _estadoColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre de lote y estado
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _estadoColor.withValues(alpha: 0.2),
                        _estadoColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.loop_rounded,
                    color: _estadoColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ciclo.nombreLote,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${ciclo.variedad} · ${ciclo.area.toStringAsFixed(1)} mz',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEstadoBadge(theme),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline steps
            _buildStep(
              context,
              icon: Icons.play_circle_rounded,
              color: const Color(0xFFF9A825),
              title: 'Apertura',
              subtitle:
                  '${ciclo.area.toStringAsFixed(1)} mz · ${ciclo.variedad}',
              date: ciclo.fechaApertura,
              isCompleted: true,
            ),
            _buildConnector(context, ciclo.estado != EstadoCiclo.abierto),
            _buildStep(
              context,
              icon: Icons.bookmark_rounded,
              color: ciclo.colorCinta?.color ?? const Color(0xFF1E88E5),
              title: 'Encintado',
              subtitle: ciclo.colorCinta != null
                  ? '${ciclo.colorCinta!.label} · ${ciclo.cantidadEncintado?.toStringAsFixed(0) ?? "-"} uds'
                  : 'Pendiente',
              date: ciclo.fechaEncintado,
              isCompleted: ciclo.estado != EstadoCiclo.abierto,
              cintaColor: ciclo.colorCinta,
            ),
            _buildConnector(context, ciclo.estado == EstadoCiclo.cosechado),
            _buildStep(
              context,
              icon: Icons.agriculture_rounded,
              color: const Color(0xFF43A047),
              title: 'Cosecha',
              subtitle: ciclo.cantidadCosecha != null
                  ? '${ciclo.cantidadCosecha!.toStringAsFixed(0)} uds · '
                        'Merma: ${ciclo.merma?.toStringAsFixed(1) ?? "—"} '
                        '(${ciclo.mermaPorcentaje?.toStringAsFixed(1) ?? "—"}%)'
                  : 'Pendiente',
              date: ciclo.fechaCosecha,
              isCompleted: ciclo.estado == EstadoCiclo.cosechado,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _estadoColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _estadoLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _estadoColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    DateTime? date,
    bool isCompleted = false,
    bool isLast = false,
    ColorCinta? cintaColor,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = isCompleted
        ? color
        : theme.colorScheme.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor.withValues(alpha: 0.12),
                border: Border.all(color: effectiveColor, width: 2),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: 16, color: effectiveColor),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (cintaColor != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cintaColor.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (date != null)
                Text(
                  _formatDate(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              if (!isLast) const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(BuildContext context, bool isActive) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.5)],
                )
              : null,
          color: isActive ? null : color,
        ),
      ),
    );
  }

  Color get _estadoColor => switch (ciclo.estado) {
    EstadoCiclo.abierto => const Color(0xFFF9A825),
    EstadoCiclo.encintado => const Color(0xFF1E88E5),
    EstadoCiclo.cosechado => const Color(0xFF43A047),
    EstadoCiclo.cancelado => const Color(0xFFE53935),
  };

  String get _estadoLabel => switch (ciclo.estado) {
    EstadoCiclo.abierto => 'Abierto',
    EstadoCiclo.encintado => 'Encintado',
    EstadoCiclo.cosechado => 'Cosechado',
    EstadoCiclo.cancelado => 'Cancelado',
  };

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
