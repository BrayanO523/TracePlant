import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../viewmodels/consultas_notifier.dart';
import '../../widgets/ciclo_timeline.dart';
// import '../../../../administracion/domain/entities/cinta.dart'; // No se usa directamente aquí por ahora

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
      body: variedades.isEmpty
          ? const Center(
              child: Text('No hay variedades registradas en ciclos activos'),
            )
          : ListView.separated(
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
                    // Navegar a resultados filtrados
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultadosConsultaView(
                          productoraId: productoraId,
                          titulo: 'Variedad: $variedad',
                          filtroInicial: (notifier) =>
                              notifier.setVariedadFilter(variedad),
                        ),
                      ),
                    );
                  },
                );
              },
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
      body: coloresList.isEmpty
          ? const Center(
              child: Text('No hay cintas registradas en ciclos activos'),
            )
          : ListView.separated(
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
                              notifier.setCintaFilter(hex),
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
class ConsultaFincaView extends ConsumerWidget {
  final String productoraId;

  const ConsultaFincaView({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultasProvider(productoraId));

    final lotes = state.ciclos.map((c) => c.nombreLote).toSet().toList();
    lotes.sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Consultar por Lote/Finca')),
      body: lotes.isEmpty
          ? const Center(child: Text('No hay lotes con ciclos activos'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final nombreLote = lotes[index];

                return _OpcionCard(
                  title: nombreLote,
                  subtitle: 'Ver historial del lote',
                  icon: Icons.grid_on_rounded,
                  color: Colors.brown,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultadosConsultaView(
                          productoraId: productoraId,
                          titulo: 'Lote: $nombreLote',
                          filtroInicial: (notifier) =>
                              notifier.setLoteFilter(nombreLote),
                        ),
                      ),
                    );
                  },
                );
              },
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
            icon: const Icon(Icons.filter_list_alt),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtros avanzados próximamente')),
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
                  value: '${state.totalEncintado.toStringAsFixed(0)}',
                ),
                _StatItem(
                  label: 'Cosechado',
                  value: '${state.totalCosechado.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista
          Expanded(
            child: state.ciclosFiltrados.isEmpty
                ? const Center(child: Text('No se encontraron resultados'))
                : ListView.builder(
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
                          ), // CORREGIDO AQUÍ
                          collapsedShape: const RoundedRectangleBorder(
                            side: BorderSide.none,
                          ), // CORREGIDO AQUÍ
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${ciclo.variedad} • ${ciclo.area} mz\nEstado: ${ciclo.estado.name.toUpperCase()}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: CicloTimeline(ciclo: ciclo),
                            ),
                          ],
                        ),
                      );
                    },
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
                      color: color.withOpacity(0.1),
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
