import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../viewmodels/asignaciones_notifier.dart';

/// Mapa de Relaciones — vista resumida de qué productoras pertenecen
/// a cada empacadora.
///
/// Usa ExpansionTiles agrupadas por Empacadora, con opción de desasignar.
/// Soporta búsqueda por nombre de empacadora o productora.
class RelacionesMap extends StatelessWidget {
  final AsignacionesState state;
  final String searchQuery;
  final void Function(String idAsignacion) onDesasignar;

  const RelacionesMap({
    super.key,
    required this.state,
    this.searchQuery = '',
    required this.onDesasignar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapa = state.asignacionesPorEmpacadora;

    if (state.empacadoras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin relaciones registradas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Asigna productoras a empacadoras\ndesde la pestaña "Asignar"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Filtrar por búsqueda
    final query = searchQuery.toLowerCase();
    final filteredEntries = mapa.entries.where((entry) {
      if (query.isEmpty) return true;
      final empMatch = entry.key.name.toLowerCase().contains(query);
      final prodMatch = entry.value.any(
        (a) => a.nombreProductora.toLowerCase().contains(query),
      );
      return empMatch || prodMatch;
    }).toList();

    if (filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados para "$searchQuery"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        itemCount: filteredEntries.length,
        itemBuilder: (context, index) {
          final entry = filteredEntries[index];
          final empacadora = entry.key;
          final asignaciones = entry.value;

          // Si buscamos una productora específica, filtrar dentro también
          final filteredAsignaciones = query.isEmpty
              ? asignaciones
              : asignaciones
                    .where(
                      (a) =>
                          a.nombreProductora.toLowerCase().contains(query) ||
                          empacadora.name.toLowerCase().contains(query),
                    )
                    .toList();

          final count = asignaciones.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.business_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  empacadora.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count productora(s) asignada(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (empacadora.location != null)
                      Text(
                        empacadora.location!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _countColor(count).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _countColor(count),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                initiallyExpanded: query.isNotEmpty || index == 0,
                children: [
                  if (filteredAsignaciones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Sin productoras asignadas',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredAsignaciones.map(
                      (a) => ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.estadoCosechado.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            size: 16,
                            color: AppColors.estadoCosechado,
                          ),
                        ),
                        title: Text(
                          a.nombreProductora,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Desde: ${_formatDate(a.fechaAsignacion)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.link_off_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          tooltip: 'Desasignar',
                          onPressed: () => onDesasignar(a.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _countColor(int count) {
    if (count == 0) return AppColors.textHint;
    if (count <= 3) return AppColors.estadoCosechado;
    if (count <= 6) return AppColors.warning;
    return AppColors.estadoCancelado;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
