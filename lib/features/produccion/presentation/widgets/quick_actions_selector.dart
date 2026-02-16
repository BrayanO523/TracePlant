import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/produccion_enums.dart';
import '../views/ciclo_form_screen.dart';

/// Clase utilitaria para manejar la lógica de selección en Acciones Rápidas.
class QuickActionsSelector {
  /// Muestra selector de lotes LIBRES para nueva siembra.
  /// Ahora valida contra ciclos activos para no mostrar lotes ocupados.
  static void showSiembraSelector(
    BuildContext context,
    WidgetRef ref,
    String productoraId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) =>
          _SiembraSelectorSheet(productoraId: productoraId, ref: ref),
    );
  }

  /// Muestra selector de ciclos en SEMBRADO para encintar.
  static void showEncintadoSelector(
    BuildContext context,
    WidgetRef ref,
    String productoraId,
  ) {
    _showSelectorSheet<CicloProduccion>(
      context: context,
      title: 'Seleccionar Lote para Encintar',
      emptyMessage: 'No hay lotes pendientes de encintado',
      stream: ref
          .read(produccionRepositoryProvider)
          .watchCiclosActivos(productoraId),
      filter: (ciclo) =>
          ciclo.estado == EstadoCiclo.sembrado ||
          ciclo.estado == EstadoCiclo.encintado,
      itemBuilder: (ciclo) => _buildCicloItem(
        ciclo,
        '${ciclo.estado == EstadoCiclo.sembrado ? "Sembrado" : "Encintado"} el ${_formatDate(ciclo.fechaSiembra)}',
      ),
      onSelect: (ciclo) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CicloFormScreen(
              productoraId: productoraId,
              idLote: ciclo.idLote,
              nombreLote: ciclo.nombreLote,
              siguientePaso: TipoEvento.encintado,
            ),
          ),
        );
      },
    );
  }

  /// Muestra selector de ciclos en ENCINTADO para cosechar.
  static void showCosechaSelector(
    BuildContext context,
    WidgetRef ref,
    String productoraId,
  ) {
    _showSelectorSheet<CicloProduccion>(
      context: context,
      title: 'Seleccionar Lote para Cosechar',
      emptyMessage: 'No hay lotes listos para cosecha',
      stream: ref
          .read(produccionRepositoryProvider)
          .watchCiclosActivos(productoraId),
      // Flexibilidad: Se puede cosechar si está Sembrado (sin cinta?) o Encintado.
      filter: (ciclo) =>
          ciclo.estado == EstadoCiclo.encintado ||
          ciclo.estado == EstadoCiclo.sembrado,
      itemBuilder: (ciclo) => _buildCicloItem(
        ciclo,
        'Estado: ${ciclo.estado.name.toUpperCase()} - Listo para cosecha',
      ),
      onSelect: (ciclo) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CicloFormScreen(
              productoraId: productoraId,
              idLote: ciclo.idLote,
              nombreLote: ciclo.nombreLote,
              siguientePaso: TipoEvento.cosecha,
            ),
          ),
        );
      },
    );
  }

  // --- Helpers Privados ---

  static void _showSelectorSheet<T>({
    required BuildContext context,
    required String title,
    required String emptyMessage,
    required Stream<List<T>> stream,
    required bool Function(T) filter,
    required Widget Function(T) itemBuilder,
    required Function(T) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _StreamSelectorSheet<T>(
        title: title,
        emptyMessage: emptyMessage,
        stream: stream,
        filter: filter,
        itemBuilder: itemBuilder,
        onSelect: onSelect,
      ),
    );
  }

  static Widget _buildLoteItem(Lote lote) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(Icons.grid_on_rounded, color: AppColors.textSecondary),
      ),
      title: Text(
        lote.nombre,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${lote.area ?? 0} mz • ${lote.variedad ?? "Sin variedad"}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  static Widget _buildCicloItem(CicloProduccion ciclo, String subtitle) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: const Icon(Icons.loop_rounded, color: AppColors.primary),
      ),
      title: Text(
        ciclo.nombreLote,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

// Widget genérico para listas simples
class _StreamSelectorSheet<T> extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final Stream<List<T>> stream;
  final bool Function(T) filter;
  final Widget Function(T) itemBuilder;
  final Function(T) onSelect;

  const _StreamSelectorSheet({
    required this.title,
    required this.emptyMessage,
    required this.stream,
    required this.filter,
    required this.itemBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<T>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final items = snapshot.data!.where(filter).toList();

                if (items.isEmpty) return _buildEmptyState(emptyMessage);

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () => onSelect(item),
                      child: itemBuilder(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Widget específico para Siembra que cruza datos con Ciclos Activos
class _SiembraSelectorSheet extends StatelessWidget {
  final String productoraId;
  final WidgetRef ref;

  const _SiembraSelectorSheet({required this.productoraId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Seleccionar Lote para Siembra',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            // Stream 1: Ciclos Activos (para saber qué lotes están ocupados realmente)
            child: StreamBuilder<List<CicloProduccion>>(
              stream: ref
                  .read(produccionRepositoryProvider)
                  .watchCiclosActivos(productoraId),
              builder: (context, ciclosSnap) {
                if (ciclosSnap.hasError)
                  return Center(child: Text('Error: ${ciclosSnap.error}'));
                if (!ciclosSnap.hasData)
                  return const Center(child: CircularProgressIndicator());

                final ciclosActivos = ciclosSnap.data!;
                final lotesOcupadosIds = ciclosActivos
                    .map((c) => c.idLote)
                    .toSet();

                // Stream 2: Lotes (para mostrarlos)
                return StreamBuilder<List<Lote>>(
                  stream: ref
                      .read(produccionRepositoryProvider)
                      .watchLotes(productoraId),
                  builder: (context, lotesSnap) {
                    if (lotesSnap.hasError)
                      return Center(child: Text('Error: ${lotesSnap.error}'));
                    if (!lotesSnap.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final todosLotes = lotesSnap.data!;

                    // FILTRO CORREGIDO:
                    // Mostrar si:
                    // 1. El modelo dice que es LIBRE
                    // 2. Y ADEMÁS, su ID no está en la lista de ciclos activos (doble check)
                    final lotesLibres = todosLotes.where((lote) {
                      final esLibrePorEstado = lote.estado == EstadoLote.libre;
                      final noTieneCicloActivo = !lotesOcupadosIds.contains(
                        lote.id,
                      );

                      // Si dice libre pero tiene ciclo -> ES OCUPADO (corrupción de datos, lo ocultamos)
                      // Si dice ocupado pero no tiene ciclo -> ES LIBRE (bug de estado bloqueado, lo mostramos)
                      // PRIORIDAD: La verdad del ciclo activo.

                      // Estrategia conservadora: Debe ser libre Y no tener ciclo.
                      // Estrategia resiliente: Si no tiene ciclo, es libre (aunque el estado diga ocupado).

                      // Vamos con la estrategia más segura para el usuario:
                      // Si NO hay ciclo activo, el lote está disponible para sembrar.
                      return noTieneCicloActivo;
                    }).toList();

                    if (lotesLibres.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay lotes libres para sembrar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: lotesLibres.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lote = lotesLibres[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CicloFormScreen(
                                  productoraId: productoraId,
                                  idLote: lote.id,
                                  nombreLote: lote.nombre,
                                  areaLote: lote.area,
                                  variedadLote: lote.variedad,
                                  siguientePaso: TipoEvento.siembra,
                                ),
                              ),
                            );
                          },
                          child: QuickActionsSelector._buildLoteItem(lote),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
