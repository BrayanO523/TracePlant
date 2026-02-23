import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';

Color _parseColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Timeline visual premium para un ciclo de producción.
class CicloTimeline extends StatelessWidget {
  final CicloProduccion ciclo;

  const CicloTimeline({super.key, required this.ciclo});

  String _getEdadText(DateTime from, DateTime to) {
    final days = to.difference(from).inDays;
    if (days <= 0) return '0 d';
    if (days < 7) return '$days d';
    final w = days ~/ 7;
    final d = days % 7;
    if (d == 0) return '$w sem';
    return '$w sem $d d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lista de pasos a renderizar
    final steps = <Widget>[];

    // 1. SIEMBRA
    steps.add(
      _buildStep(
        context,
        icon: Icons.grass_rounded,
        color: AppColors.estadoSembrado, // Amber
        title: 'Siembra',
        subtitle: '${ciclo.area.toStringAsFixed(1)} mz · ${ciclo.variedad}',
        date: ciclo.fechaSiembra,
        isCompleted: true,
        ageText: 'Día 0',
      ),
    );

    // 2. ENCINTADOS (Múltiples)
    if (ciclo.encintados.isNotEmpty) {
      steps.add(_buildConnector(context, true));

      for (var i = 0; i < ciclo.encintados.length; i++) {
        final encintado = ciclo.encintados[i];
        final isLastEncintado = i == ciclo.encintados.length - 1;
        final isCosechado = ciclo.estado == EstadoCiclo.cosechado;

        steps.add(
          _buildStep(
            context,
            icon: Icons.bookmark_rounded,
            color: _parseColor(encintado.cintaColorHex),
            title: 'Encintado ${i + 1}',
            subtitle:
                '${encintado.cintaNombre} · ${encintado.cantidad.toStringAsFixed(2)} uds',
            date: encintado.fecha,
            isCompleted: true,
            cintaColorHex: encintado.cintaColorHex,
            ageText:
                'Edad: ${_getEdadText(ciclo.fechaSiembra, encintado.fecha)}',
          ),
        );

        // Si no es el último evento (hay cosecha, o hay más encintados), conector activo
        if (!isLastEncintado || isCosechado) {
          steps.add(_buildConnector(context, true));
        }
      }
    } else {
      // Si no hay encintados pero el estado avanza (raro, pero defensive)
      if (ciclo.estado != EstadoCiclo.sembrado) {
        steps.add(_buildConnector(context, false));
        steps.add(
          _buildStep(
            context,
            icon: Icons.bookmark_border_rounded,
            title: 'Encintado',
            subtitle: 'Pendiente',
            isCompleted: false,
            color: AppColors.estadoEncintado, // Blue default
          ),
        );
      }
    }

    // 3. COSECHA
    if (ciclo.estado == EstadoCiclo.cosechado ||
        (ciclo.encintados.isNotEmpty &&
            ciclo.estado == EstadoCiclo.encintado)) {
      // Mostrar nodo de Cosecha (Pendiente o Completado) si ya hay encintados
      final isCosechado = ciclo.estado == EstadoCiclo.cosechado;

      if (!isCosechado && ciclo.encintados.isNotEmpty) {
        steps.add(_buildConnector(context, false));
      }

      steps.add(
        _buildStep(
          context,
          icon: Icons.agriculture_rounded,
          color: AppColors.estadoCosechado, // Green
          title: 'Cosecha',
          subtitle: isCosechado && ciclo.cantidadCosecha != null
              ? '${ciclo.cantidadCosecha!.toStringAsFixed(0)} uds · Merma: ${ciclo.merma?.toStringAsFixed(1) ?? "—"}'
              : 'Pendiente',
          date: ciclo.fechaCosecha,
          isCompleted: isCosechado,
          isLast: true,
          ageText: isCosechado && ciclo.fechaCosecha != null
              ? 'Edad a cosecha: ${_getEdadText(ciclo.fechaSiembra, ciclo.fechaCosecha!)}'
              : 'Edad actual: ${_getEdadText(ciclo.fechaSiembra, DateTime.now())}',
        ),
      );
    }

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
                    Icons.history_edu_rounded,
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
            const SizedBox(height: 24),

            // Renderizamos los steps dinámicos
            ...steps,
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
    String? cintaColorHex,
    String? ageText,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = isCompleted
        ? color
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono y línea vertical (si no es el último)
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
              // El conector se maneja externamente en el loop principal
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0), // Spacing
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
                      if (cintaColorHex != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _parseColor(cintaColorHex),
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
                  if (date != null || ageText != null)
                    Row(
                      children: [
                        if (date != null)
                          Text(
                            _formatDate(date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        if (date != null && ageText != null)
                          Text(
                            ' · ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        if (ageText != null)
                          Text(
                            ageText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, bool isActive) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
      ), // Center align with 32px circle (16 - 1 = 15)
      child: Container(
        width: 2,
        height: 24, // Altura fija del conector entre nodos
        color: isActive ? color : color.withValues(alpha: 0.5),
      ),
    );
  }

  Color get _estadoColor => switch (ciclo.estado) {
    EstadoCiclo.sembrado => AppColors.estadoSembrado,
    EstadoCiclo.encintado => AppColors.estadoEncintado,
    EstadoCiclo.cosechado => AppColors.estadoCosechado,
    EstadoCiclo.cancelado => AppColors.estadoCancelado,
  };

  String get _estadoLabel => switch (ciclo.estado) {
    EstadoCiclo.sembrado => 'Sembrado',
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
