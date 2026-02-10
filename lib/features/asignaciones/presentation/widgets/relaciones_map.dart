import 'package:flutter/material.dart';
import '../viewmodels/asignaciones_notifier.dart';

/// Mapa de Relaciones — vista resumida de qué productoras pertenecen
/// a cada empacadora.
///
/// Usa ExpansionTiles agrupadas por Empacadora, con opción de desasignar.
class RelacionesMap extends StatelessWidget {
  final AsignacionesState state;
  final void Function(String idAsignacion) onDesasignar;

  const RelacionesMap({
    super.key,
    required this.state,
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

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: mapa.length,
        itemBuilder: (context, index) {
          final entry = mapa.entries.elementAt(index);
          final empacadora = entry.key;
          final asignaciones = entry.value;
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
                subtitle: Text(
                  '$count productora(s) asignada(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                initiallyExpanded: index == 0,
                children: [
                  if (asignaciones.isEmpty)
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
                    ...asignaciones.map(
                      (a) => ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(
                            0xFF43A047,
                          ).withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            size: 16,
                            color: Color(0xFF43A047),
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
    if (count == 0) return const Color(0xFF9E9E9E);
    if (count <= 3) return const Color(0xFF43A047);
    if (count <= 6) return const Color(0xFFFB8C00);
    return const Color(0xFFE53935);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
