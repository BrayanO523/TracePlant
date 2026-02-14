import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/produccion_enums.dart';
import 'estado_indicador.dart';

/// Card premium de lote con info de área, variedad, y estado visual.
class LoteCard extends StatelessWidget {
  final Lote lote;
  final VoidCallback? onTap;

  const LoteCard({super.key, required this.lote, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOcupado = lote.estado == EstadoLote.ocupado;
    final accentColor = isOcupado
        ? AppColors.estadoSembrado
        : AppColors.estadoCosechado;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOcupado
              ? accentColor.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isOcupado ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono con gradiente
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.15),
                      accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.grass_rounded, color: accentColor, size: 26),
              ),
              const SizedBox(width: 14),
              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lote.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Área y variedad
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.square_foot_rounded,
                          label: '${lote.area.toStringAsFixed(1)} mz',
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.eco_rounded,
                          label: lote.variedad,
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    EstadoIndicador(
                      estadoLote: lote.estado,
                      colorCinta: lote.colorCinta,
                    ),
                  ],
                ),
              ),
              // Flecha
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
