import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../viewmodels/consultas_notifier.dart';
import '../../widgets/ciclo_timeline.dart';
import '../widgets/consultas_filter_modal.dart';
import '../../../../administracion/domain/entities/finca.dart';
import '../../../domain/entities/lote.dart'; // Lote de Produccion
import '../../views/lote_history_screen.dart';
import '../../../../../core/utils/formatters.dart';

// ─── CONSULTA POR VARIEDAD ───────────────────────────────────────────────────
class ConsultaVariedadView extends ConsumerWidget {
  final String productoraId;

  const ConsultaVariedadView({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultasProvider(productoraId));

    // Extraer variedades únicas de los ciclos activos
    final variedades = state.ciclos
        .map((c) => c.variedad)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    variedades.sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Consultar por Variedad')),
      body: Column(
        children: [
          // Resumen Global de Variedades
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Variedades',
                  value: variedades.length.toString(),
                ),
                _StatItem(
                  label: 'Lotes Activos',
                  value: state.ciclos.length.toString(),
                ),
                _StatItem(
                  label: 'Encintado Total',
                  value: AppFormatters.formatInt(state.totalEncintado),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(consultasProvider(productoraId).notifier).refresh(),
              child: variedades.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No hay variedades registradas en ciclos activos',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: variedades.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final variedad = variedades[index];
                        final count = state.ciclos
                            .where((c) => c.variedad == variedad)
                            .length;

                        return _OpcionCard(
                          title: variedad,
                          subtitle: '$count lotes activos',
                          icon: Icons.eco_rounded,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultadosConsultaView(
                                  productoraId: productoraId,
                                  titulo: 'Variedad: $variedad',
                                  filtroInicial: (notifier) =>
                                      notifier.setFilters(
                                        variedadFilter: variedad,
                                        resetOthers: true,
                                      ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CONSULTA POR CINTA ──────────────────────────────────────────────────────
class ConsultaCintaView extends ConsumerWidget {
  final String productoraId;

  const ConsultaCintaView({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultasProvider(productoraId));

    // Extraer colores únicos de cintas en ciclos activos
    final coloresMap = <String, int>{}; // Hex -> Count

    for (var c in state.ciclos) {
      for (var e in c.encintados) {
        coloresMap[e.cintaColorHex] = (coloresMap[e.cintaColorHex] ?? 0) + 1;
      }
    }

    final coloresList = coloresMap.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Consultar por Cinta')),
      body: Column(
        children: [
          // Resumen Global de Cintas
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Cintas Distintas',
                  value: coloresList.length.toString(),
                ),
                _StatItem(
                  label: 'Lotes Activos',
                  value: state.ciclos.length.toString(),
                ),
                _StatItem(
                  label: 'Encintado Total',
                  value: AppFormatters.formatInt(state.totalEncintado),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(consultasProvider(productoraId).notifier).refresh(),
              child: coloresList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No hay cintas registradas en ciclos activos',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: coloresList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final hex = coloresList[index];
                        final count = coloresMap[hex];
                        final color = _parseColor(hex);

                        return _OpcionCard(
                          title: 'Cinta',
                          subtitle: '$count registros',
                          icon: Icons.circle,
                          color: color,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultadosConsultaView(
                                  productoraId: productoraId,
                                  titulo: 'Filtro por Color',
                                  filtroInicial: (notifier) =>
                                      notifier.setFilters(
                                        cintaFilter: hex,
                                        resetOthers: true,
                                      ),
                                ),
                              ),
                            );
                          },
                          customLeading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    if (hex.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

// ─── CONSULTA POR FINCA ──────────────────────────────────────────────────────
// ─── CONSULTA POR FINCA (Jerarquía: Finca -> Lotes) ──────────────────────────
class ConsultaFincaView extends ConsumerWidget {
  final String productoraId;

  const ConsultaFincaView({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultasProvider(productoraId));

    // 1. Identificar Fincas con actividad
    //    a) Obtener IDs de lotes con ciclos activos
    final loteIdsConCiclos = state.ciclos.map((c) => c.idLote).toSet();

    //    b) Filtrar lotes activos (usando la lista maestra de lotes)
    final lotesActivos = state.lotes.where(
      (l) => loteIdsConCiclos.contains(l.id),
    );

    //    c) Obtener IDs de fincas relacionadas
    final fincaIdsConActividad = lotesActivos.map((l) => l.fincaId).toSet();

    //    d) Filtrar fincas para mostrar (usando lista maestra de fincas)
    final fincasDisplay = state.fincas
        .where((f) => fincaIdsConActividad.contains(f.id))
        .toList();

    // Ordenar alfabéticamente
    fincasDisplay.sort((a, b) => a.nombre.compareTo(b.nombre));

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Finca')),
      body: Column(
        children: [
          // Resumen Global de Fincas
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Fincas Activas',
                  value: fincasDisplay.length.toString(),
                ),
                _StatItem(
                  label: 'Lotes Activos',
                  value: lotesActivos.length.toString(),
                ),
                _StatItem(
                  label: 'Encintado Total',
                  value: AppFormatters.formatInt(state.totalEncintado),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(consultasProvider(productoraId).notifier).refresh(),
              child: fincasDisplay.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text('No hay fincas con producción activa'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: fincasDisplay.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final finca = fincasDisplay[index];
                        // Contar lotes activos en esta finca
                        final lotesCount = lotesActivos
                            .where((l) => l.fincaId == finca.id)
                            .length;

                        return _OpcionCard(
                          title: finca.nombre,
                          subtitle: '$lotesCount lotes activos',
                          icon: Icons.domain, // Icono de granja/finca
                          color: Colors.brown,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConsultaLotesFincaView(
                                  productoraId: productoraId,
                                  finca: finca,
                                  lotesDeFinca: lotesActivos
                                      .where((l) => l.fincaId == finca.id)
                                      .toList(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConsultaLotesFincaView extends ConsumerWidget {
  final String productoraId;
  final Finca finca;
  final List<Lote> lotesDeFinca;

  const ConsultaLotesFincaView({
    super.key,
    required this.productoraId,
    required this.finca,
    required this.lotesDeFinca,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ordenar lotes por nombre para facilitar búsqueda
    final displayLotes = List<Lote>.from(lotesDeFinca)
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final state = ref.watch(consultasProvider(productoraId));
    final loteIds = lotesDeFinca.map((l) => l.id).toSet();
    final ciclosFinca = state.ciclos.where((c) => loteIds.contains(c.idLote));

    double encintadoFinca = 0;
    for (var c in ciclosFinca) {
      for (var e in c.encintados) {
        encintadoFinca += e.cantidad;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Lotes de ${finca.nombre}')),
      body: Column(
        children: [
          // Resumen de Lotes en Finca específica
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Lotes Activos',
                  value: displayLotes.length.toString(),
                ),
                _StatItem(
                  label: 'Ciclos',
                  value: ciclosFinca.length.toString(),
                ),
                _StatItem(
                  label: 'Encintado',
                  value: AppFormatters.formatInt(encintadoFinca),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(consultasProvider(productoraId).notifier).refresh(),
              child: displayLotes.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text('No hay lotes activos en esta finca'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: displayLotes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lote = displayLotes[index];

                        // Información adicional del lote obtenida del ciclo?
                        // Podríamos buscar el ciclo para mostrar la variedad, pero Lote ya tiene variedad?
                        // El Lote de produccion tiene variedad.

                        return _OpcionCard(
                          title: lote.nombre,
                          subtitle:
                              'Variedad: ${lote.variedad} • ${lote.area} mz',
                          icon: Icons.grid_on_rounded,
                          color: Colors.green.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultadosConsultaView(
                                  productoraId: productoraId,
                                  titulo: 'Lote: ${lote.nombre}',
                                  // IMPORTANTE: Filtrar por Nombre de Lote o ID?
                                  // El notifier usa loteFilter.
                                  // Veamos setFilters: loteFilter: loteFilter.
                                  // Y el filtro lo aplica sobre ciclo.nombreLote o ciclo.idLote?
                                  // ConsultasNotifier usa: ciclo.nombreLote.toLowerCase().contains(filter.toLowerCase())
                                  // Así que pasamos el NOMBRE.
                                  filtroInicial: (notifier) =>
                                      notifier.setFilters(
                                        loteFilter: lote.id,
                                        resetOthers: true,
                                      ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RESULTADOS FILTRADOS ────────────────────────────────────────────────────
class ResultadosConsultaView extends ConsumerStatefulWidget {
  final String productoraId;
  final String titulo;
  final Function(ConsultasNotifier) filtroInicial;

  const ResultadosConsultaView({
    super.key,
    required this.productoraId,
    required this.titulo,
    required this.filtroInicial,
  });

  @override
  ConsumerState<ResultadosConsultaView> createState() =>
      _ResultadosConsultaViewState();
}

class _ResultadosConsultaViewState
    extends ConsumerState<ResultadosConsultaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.filtroInicial(
        ref.read(consultasProvider(widget.productoraId).notifier),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultasProvider(widget.productoraId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
            ), // Icono ajustado a "Configurar"
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    ConsultasFilterModal(productoraId: widget.productoraId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Lotes',
                  value: '${state.ciclosFiltrados.length}',
                ),
                _StatItem(
                  label: 'Encintado',
                  value: AppFormatters.formatInt(state.totalEncintado),
                ),
                _StatItem(
                  label: 'Cosechado',
                  value: AppFormatters.formatInt(state.totalCosechado),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref
                  .read(consultasProvider(widget.productoraId).notifier)
                  .refresh(),
              child: state.ciclosFiltrados.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        const Center(
                          child: Text('No se encontraron resultados'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: state.ciclosFiltrados.length,
                      itemBuilder: (context, index) {
                        final ciclo = state.ciclosFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ExpansionTile(
                            shape: const RoundedRectangleBorder(
                              side: BorderSide.none,
                            ),
                            collapsedShape: const RoundedRectangleBorder(
                              side: BorderSide.none,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                ciclo.nombreLote.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              ciclo.nombreLote,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${ciclo.variedad} • ${ciclo.area} mz\nEstado: ${ciclo.estado.name.toUpperCase()}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: CicloTimeline(ciclo: ciclo),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LoteHistoryScreen(
                                          productoraId: widget.productoraId,
                                          loteId: ciclo.idLote,
                                          nombreLote: ciclo.nombreLote,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Ver historial del lote'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      40,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS COMPARTIDOS ─────────────────────────────────────────────────────

class _OpcionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? customLeading;

  const _OpcionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.customLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              customLeading ??
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
