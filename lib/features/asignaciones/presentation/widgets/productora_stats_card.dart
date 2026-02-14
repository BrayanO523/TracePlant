import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../productora/domain/entities/productora.dart';
import '../../../produccion/presentation/viewmodels/productora_stats_notifier.dart';

class ProductoraStatsCard extends ConsumerStatefulWidget {
  final Productora productora;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const ProductoraStatsCard({
    super.key,
    required this.productora,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<ProductoraStatsCard> createState() =>
      _ProductoraStatsCardState();
}

class _ProductoraStatsCardState extends ConsumerState<ProductoraStatsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected ? colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header (Siempre visible)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: widget.isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.agriculture_rounded,
                color: widget.isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            title: Text(
              widget.productora.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: widget.isSelected
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              [
                widget.productora.location ?? 'Sin ubicación',
                if (widget.productora.rnt != null)
                  'RNT: ${widget.productora.rnt}',
              ].join(' • '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón expandir/colapsar
                IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.analytics_outlined,
                    color: _isExpanded
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: _isExpanded ? 'Ocultar resumen' : 'Ver resumen',
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                // Checkbox de selección
                Checkbox(
                  value: widget.isSelected,
                  onChanged: widget.onSelectionChanged,
                  activeColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            onTap: () {
              // Tap en la tarjeta también selecciona/deselecciona
              widget.onSelectionChanged(!widget.isSelected);
            },
          ),

          // Panel Expandible (Estadísticas)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _isExpanded
                ? _buildStatsPanel(context)
                : const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(BuildContext context) {
    // id_productora en ciclos usa el ID del documento de la productora.
    final statsAsync = ref.watch(productoraStatsProvider(widget.productora.id));
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'RESUMEN DE PRODUCCIÓN INTELIGENTE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error al cargar datos',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            data: (stats) {
              if (stats.ciclosActivos == 0 && stats.lotesActivos == 0) {
                return _buildEmptyStats(theme);
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    theme,
                    label: 'Ciclos Activos',
                    value: stats.ciclosActivos.toString(),
                    icon: Icons.loop_rounded,
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    theme,
                    label: 'Lotes',
                    value: stats.lotesActivos.toString(),
                    icon: Icons.grass_rounded,
                    color: Colors.teal,
                  ),
                  _buildStatItem(
                    theme,
                    label: 'Vol. Cosecha',
                    value: '${stats.volumenCosecha.toStringAsFixed(0)} lbs',
                    icon: Icons.scale_rounded,
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    theme,
                    label: 'En Cinta',
                    value: '${stats.volumenEncintado.toStringAsFixed(0)} lbs',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orange,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStats(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 16,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Sin actividad productiva reciente',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
