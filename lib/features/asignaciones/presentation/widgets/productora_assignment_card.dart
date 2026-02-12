import 'package:flutter/material.dart';
import '../../../productora/domain/entities/productora.dart';
import '../../../produccion/domain/entities/lote.dart';

class ProductoraAssignmentCard extends StatelessWidget {
  final Productora productora;
  final List<Lote> lotes;
  final bool isSelected;
  final bool isAssignedToOther; // Futuro: si queremos mostrar las ya asignadas
  final ValueChanged<bool> onSelectionChanged;

  const ProductoraAssignmentCard({
    super.key,
    required this.productora,
    this.lotes = const [],
    required this.isSelected,
    this.isAssignedToOther = false,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final totalArea = lotes.fold<double>(0, (sum, l) => sum + l.area);
    final activeLotes = lotes.length;

    return Card(
      elevation: isSelected ? 4 : 0,
      shadowColor: scheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? scheme.surface : scheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => onSelectionChanged(!isSelected),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con Checkbox + Nombre
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productora.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          productora.location ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) => onSelectionChanged(v ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Resumen de Capacidad
              Row(
                children: [
                  Icon(Icons.grass_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${totalArea.toStringAsFixed(1)} mz',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• $activeLotes lotes',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Lista mini de lotes
              if (lotes.isEmpty)
                Text(
                  'Sin lotes registrados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.outline,
                  ),
                )
              else
                ...lotes
                    .take(3)
                    .map(
                      (lote) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: scheme.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${lote.nombre} (${lote.area}mz)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              lote.variedad,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: scheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

              if (lotes.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${lotes.length - 3} más...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
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
