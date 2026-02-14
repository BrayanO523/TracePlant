import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/produccion_enums.dart';
import 'color_cinta_ext.dart';

/// Widget que muestra un badge de estado premium con color real de la cinta.
class EstadoIndicador extends StatelessWidget {
  final EstadoCiclo? estadoCiclo;
  final EstadoLote? estadoLote;
  final ColorCinta? colorCinta;

  const EstadoIndicador({
    super.key,
    this.estadoCiclo,
    this.estadoLote,
    this.colorCinta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _backgroundColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Punto indicador
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: _backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _backgroundColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (colorCinta != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colorCinta!.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorCinta!.color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                colorCinta!.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _backgroundColor {
    if (estadoCiclo != null) {
      return switch (estadoCiclo!) {
        EstadoCiclo.sembrado => AppColors.estadoSembrado,
        EstadoCiclo.encintado => AppColors.estadoEncintado,
        EstadoCiclo.cosechado => AppColors.estadoCosechado,
        EstadoCiclo.cancelado => AppColors.estadoCancelado,
      };
    }
    if (estadoLote != null) {
      return estadoLote == EstadoLote.libre
          ? AppColors.estadoCosechado
          : AppColors.estadoSembrado;
    }
    return Colors.grey;
  }

  String get _label {
    if (estadoCiclo != null) {
      return switch (estadoCiclo!) {
        EstadoCiclo.sembrado => 'Sembrado',
        EstadoCiclo.encintado => 'Encintado',
        EstadoCiclo.cosechado => 'Cosechado',
        EstadoCiclo.cancelado => 'Cancelado',
      };
    }
    if (estadoLote != null) {
      return estadoLote == EstadoLote.libre ? 'Disponible' : 'En Producción';
    }
    return 'Desconocido';
  }
}
