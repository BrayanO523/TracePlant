import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/constants/firestore_paths.dart';
import '../viewmodels/consultas_notifier.dart';
import '../widgets/consultas_filter_bar.dart';
import '../widgets/export_button.dart';
import '../logic/pdf_report_generator.dart';
import '../../widgets/ciclo_timeline.dart';
import '../../../../../features/administracion/domain/entities/cinta.dart';

class ConsultasScreen extends ConsumerStatefulWidget {
  final String productoraId;

  const ConsultasScreen({super.key, required this.productoraId});

  @override
  ConsumerState<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends ConsumerState<ConsultasScreen> {
  @override
  void initState() {
    super.initState();
  }

  // --- Actions ---

  Future<void> _pickDateRange(BuildContext context) async {
    final state = ref.read(consultasProvider(widget.productoraId));
    final notifier = ref.read(consultasProvider(widget.productoraId).notifier);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: (state.fechaInicio != null && state.fechaFin != null)
          ? DateTimeRange(start: state.fechaInicio!, end: state.fechaFin!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      notifier.setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _exportarReporte() async {
    final state = ref.read(consultasProvider(widget.productoraId));
    final notifier = ref.read(consultasProvider(widget.productoraId).notifier);

    String nombreProductora = "Productora";
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.productoras)
          .doc(widget.productoraId)
          .get();
      if (doc.exists) {
        nombreProductora = doc.data()?['nombre_empresa'] ?? "Productora";
      }
    } catch (_) {}

    // Obtener lista de Cintas para mapear colores reales
    List<Cinta> cintas = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestorePaths.cintas)
          .where('productoraId', isEqualTo: widget.productoraId)
          .get();

      cintas = snapshot.docs
          .map(
            (d) => Cinta(
              id: d.id,
              color: d.data()['color'] ?? '',
              descripcion: d.data()['descripcion'] ?? '',
              colorHex: d.data()['colorHex'] ?? '#000000',
              productoraId: d.data()['productoraId'] ?? widget.productoraId,
            ),
          )
          .toList();
    } catch (_) {}

    await PdfReportGenerator.generateAndPrint(
      state,
      notifier.getStatsPorColor(),
      notifier.getProduccionSemanal(),
      nombreProductora,
      cintas,
    );
  }

  void _showCicloTimeline(dynamic ciclo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: CicloTimeline(ciclo: ciclo),
        ),
      ),
    );
  }

  void _showProyecciones(ConsultasState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Proyección de Cosecha',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${state.proximasCosechas.length} lotes · ${state.semanasParaCosecha} sem config.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: state.proximasCosechas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin cosechas proyectadas',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No hay ciclos encintados activos',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.proximasCosechas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = state.proximasCosechas[index];
                          return _ProyeccionCard(
                            proyeccion: p,
                            onTap: () => _showCicloTimeline(p.ciclo),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInventario(ConsultasState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventario en Campo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${state.inventario.length} lotes · ${state.totalInventario.toStringAsFixed(0)} cintas activas',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: state.inventario.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin cintas activas en campo',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.inventario.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final ciclo = state.inventario[index];
                          return _ResultCard(
                            ciclo: ciclo,
                            onTap: () => _showCicloTimeline(ciclo),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultasProvider(widget.productoraId));
    final notifier = ref.read(consultasProvider(widget.productoraId).notifier);

    final variedades = state.ciclos.map((c) => c.variedad).toSet().toList()
      ..sort();
    final lotes = state.ciclos.map((c) => c.nombreLote).toSet().toList()
      ..sort();

    // Agrupar ciclos filtrados por nombre de lote
    final Map<String, List<dynamic>> ciclosPorLote = {};
    for (var ciclo in state.ciclosFiltrados) {
      final lote = ciclo.nombreLote ?? 'Sin Lote';
      ciclosPorLote.putIfAbsent(lote, () => []).add(ciclo);
    }
    final loteNames = ciclosPorLote.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text(
              'Consultas y Reportes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: Colors.white,
            floating: true,
            pinned: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            actions: [
              ExportButton(onTap: _exportarReporte, isLoading: false),
              const SizedBox(width: 8),
            ],
          ),

          // 1) Filtros arriba
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterDelegate(
              minHeight: 80,
              maxHeight: 80,
              child: ConsultasFilterBar(
                startDate: state.fechaInicio,
                endDate: state.fechaFin,
                variedadFilter: state.variedadFilter,
                loteFilter: state.loteFilter,
                cintaFilter: state.cintaFilter,
                onDateTap: () => _pickDateRange(context),
                onClearTap: notifier.clearFilters,
                onVariedadChanged: notifier.setVariedadFilter,
                onLoteChanged: (v) {},
                variedadesDisponibles: variedades,
                lotesDisponibles: lotes,
              ),
            ),
          ),

          // 2) Summary Cards + Botón Inventario
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Ciclos',
                          value: '${state.totalCiclos}',
                          icon: Icons.grid_view_rounded,
                          accentColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Cosechado',
                          value: '${state.totalCosechado.toStringAsFixed(0)}',
                          icon: Icons.inventory_2_rounded,
                          accentColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3) Botón de Inventario (reemplaza gráficos)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showInventario(state),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.layers_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Inventario en Campo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${state.inventario.length} lotes · ${state.totalInventario.toStringAsFixed(0)} cintas activas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3b) Botón de Proyección de Cosecha
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showProyecciones(state),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Proyección de Cosecha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${state.proximasCosechas.length} lotes por cosechar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Encabezado de Histórico
                  const Text(
                    'Histórico por Lote',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4) Lotes con su histórico
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (state.ciclosFiltrados.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _EmptyState(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final loteName = loteNames[index];
                  final ciclosDelLote = ciclosPorLote[loteName]!;
                  return _LoteSection(
                    loteName: loteName,
                    ciclos: ciclosDelLote,
                    onCicloTap: _showCicloTimeline,
                  );
                }, childCount: loteNames.length),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Widgets Privados ---

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyFilterDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF9FAFB),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyFilterDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección agrupada por Lote: muestra el nombre del lote y sus ciclos
class _LoteSection extends StatelessWidget {
  final String loteName;
  final List<dynamic> ciclos;
  final void Function(dynamic ciclo) onCicloTap;

  const _LoteSection({
    required this.loteName,
    required this.ciclos,
    required this.onCicloTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular totales del lote
    double totalCintas = 0;
    double totalCosecha = 0;
    for (var ciclo in ciclos) {
      totalCintas += ciclo.totalEncintado;
      if (ciclo.cantidadCosecha != null) {
        totalCosecha += ciclo.cantidadCosecha!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del lote
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.terrain_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loteName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ciclos.length} ciclos · ${totalCintas.toStringAsFixed(0)} cintas · ${totalCosecha.toStringAsFixed(0)} Kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de ciclos del lote
          ...ciclos.map((ciclo) {
            final dateStr =
                "${ciclo.fechaSiembra.day}/${ciclo.fechaSiembra.month}/${ciclo.fechaSiembra.year}";

            Color indicatorColor = Colors.grey.shade300;
            if (ciclo.encintados.isNotEmpty) {
              try {
                indicatorColor = Color(
                  int.tryParse(
                        ciclo.encintados.last.cintaColorHex.replaceFirst(
                          '#',
                          '0xff',
                        ),
                      ) ??
                      0xFFCCCCCC,
                );
              } catch (_) {}
            }

            double cicloEncintado = 0;
            for (var e in ciclo.encintados) {
              cicloEncintado += e.cantidad;
            }

            return InkWell(
              onTap: () => onCicloTap(ciclo),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    // Indicador de color
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info del ciclo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ciclo.variedad} · $dateStr',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ciclo.estado.toString().split('.').last}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Datos numéricos
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cicloEncintado.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'cintas',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade300,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final dynamic ciclo;
  final VoidCallback onTap;
  final String? cintaFilter;

  const _ResultCard({
    required this.ciclo,
    required this.onTap,
    this.cintaFilter,
  });

  @override
  Widget build(BuildContext context) {
    double totalEncintado = 0;
    for (var e in ciclo.encintados) {
      if (cintaFilter == null || e.cintaColorHex == cintaFilter) {
        totalEncintado += e.cantidad;
      }
    }

    Color indicatorColor = Colors.grey.shade300;
    if (ciclo.encintados.isNotEmpty) {
      if (cintaFilter != null) {
        indicatorColor = Color(
          int.tryParse(cintaFilter!.replaceFirst('#', '0xff')) ?? 0xFFCCCCCC,
        );
      } else {
        try {
          indicatorColor = Color(
            int.tryParse(
                  ciclo.encintados.last.cintaColorHex.replaceFirst('#', '0xff'),
                ) ??
                0xFFCCCCCC,
          );
        } catch (_) {}
      }
    }

    final dateStr =
        "${ciclo.fechaSiembra.day}/${ciclo.fechaSiembra.month}/${ciclo.fechaSiembra.year}";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ciclo.nombreLote ?? 'Lote Desconocido',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ciclo.variedad} · $dateStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalEncintado.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Cintas',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card individual de proyección de cosecha.
/// Usa badges de texto + icono para urgencia (no círculos de color)
/// para evitar confusión con los colores de cinta.
class _ProyeccionCard extends StatelessWidget {
  final ProximaCosechaLocal proyeccion;
  final VoidCallback onTap;

  const _ProyeccionCard({required this.proyeccion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dias = proyeccion.diasRestantes;
    final ciclo = proyeccion.ciclo;

    // Determinar urgencia con icono + texto (sin círculos de color)
    final IconData urgencyIcon;
    final String urgencyLabel;
    final Color urgencyBg;
    final Color urgencyFg;

    if (dias < 0) {
      urgencyIcon = Icons.warning_amber_rounded;
      urgencyLabel = 'Vencido ${-dias}d';
      urgencyBg = const Color(0xFFFFF0F0);
      urgencyFg = const Color(0xFFD32F2F);
    } else if (dias <= 14) {
      urgencyIcon = Icons.schedule_rounded;
      urgencyLabel = '$dias días';
      urgencyBg = const Color(0xFFFFF8E1);
      urgencyFg = const Color(0xFFE65100);
    } else {
      urgencyIcon = Icons.hourglass_bottom_rounded;
      urgencyLabel = '$dias días';
      urgencyBg = const Color(0xFFF0F4F8);
      urgencyFg = const Color(0xFF546E7A);
    }

    final fechaStr =
        '${proyeccion.fechaProyectada.day}/${proyeccion.fechaProyectada.month}/${proyeccion.fechaProyectada.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono de calendario
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info del lote
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ciclo.nombreLote,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ciclo.variedad} · ${ciclo.totalEncintado.toStringAsFixed(0)} uds',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Est: $fechaStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge de urgencia (texto, no circle de color)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: urgencyBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(urgencyIcon, size: 14, color: urgencyFg),
                    const SizedBox(width: 4),
                    Text(
                      urgencyLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: urgencyFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Sin datos para mostrar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}
