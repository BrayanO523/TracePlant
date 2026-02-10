import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../core/utils/seeder.dart';
import '../viewmodels/lotes_notifier.dart';
import '../viewmodels/produccion_notifier.dart';
import '../widgets/lote_card.dart';
import '../widgets/ciclo_timeline.dart';
import '../../domain/entities/produccion_enums.dart';
import 'ciclo_form_screen.dart';

/// Pantalla principal premium del módulo de producción.
class ProduccionHomeScreen extends ConsumerStatefulWidget {
  final String productoraId;

  const ProduccionHomeScreen({super.key, required this.productoraId});

  @override
  ConsumerState<ProduccionHomeScreen> createState() =>
      _ProduccionHomeScreenState();
}

class _ProduccionHomeScreenState extends ConsumerState<ProduccionHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  EstadoCiclo? _filtroEstado; // null = Todos
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lotesState = ref.watch(lotesNotifierProvider(widget.productoraId));
    final produccionState = ref.watch(
      produccionNotifierProvider(widget.productoraId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Producción'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.grass_rounded), text: 'Lotes'),
            Tab(icon: Icon(Icons.timeline_rounded), text: 'Ciclos'),
          ],
        ),
        actions: [
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          // DEBUG SEED BUTTON
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            tooltip: 'Generar Datos de Prueba',
            onPressed: () async {
              await DataSeeder().seedProduccion(widget.productoraId);
              ref.invalidate(lotesNotifierProvider(widget.productoraId));
              ref.invalidate(produccionNotifierProvider(widget.productoraId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Datos de prueba generados!')),
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLotesTab(lotesState, produccionState),
          _buildCiclosTab(produccionState),
        ],
      ),
      // FAB para crear nuevo lote
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearLoteDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Lote'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB LOTES
  // ═══════════════════════════════════════════════════════

  Widget _buildLotesTab(
    LotesState lotesState,
    ProduccionState produccionState,
  ) {
    if (lotesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lotesState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(lotesState.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(lotesNotifierProvider(widget.productoraId));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (lotesState.lotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grass_rounded,
                size: 40,
                color: Color(0xFF43A047),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin Lotes Registrados',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer lote para comenzar\na registrar producción',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(lotesNotifierProvider(widget.productoraId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: lotesState.lotes.length,
        itemBuilder: (context, index) {
          final lote = lotesState.lotes[index];
          final siguientePaso = produccionState.siguientePaso(lote.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LoteCard(
              lote: lote,
              onTap: () =>
                  _navigateToCicloForm(lote.id, lote.nombre, siguientePaso),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB CICLOS (con búsqueda y filtros)
  // ═══════════════════════════════════════════════════════

  Widget _buildCiclosTab(ProduccionState produccionState) {
    if (produccionState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (produccionState.ciclos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timeline_rounded,
                size: 40,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin Ciclos de Producción',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Los ciclos aparecerán aquí cuando\nregistres una apertura en un lote',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // ── Filtrar ciclos ──
    final ciclosFiltrados = produccionState.ciclos.where((c) {
      final matchEstado = _filtroEstado == null || c.estado == _filtroEstado;
      final matchBusqueda =
          _searchQuery.isEmpty ||
          c.nombreLote.toLowerCase().contains(_searchQuery) ||
          c.variedad.toLowerCase().contains(_searchQuery);
      return matchEstado && matchBusqueda;
    }).toList();

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(produccionNotifierProvider(widget.productoraId));
      },
      child: CustomScrollView(
        slivers: [
          // ── Barra de búsqueda + filtros ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por lote o variedad…',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(null, 'Todos', Icons.apps_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          EstadoCiclo.abierto,
                          'Abierto',
                          Icons.lock_open_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          EstadoCiclo.encintado,
                          'Encintado',
                          Icons.palette_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          EstadoCiclo.cosechado,
                          'Cosechado',
                          Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Contador de resultados
                  Text(
                    '${ciclosFiltrados.length} de ${produccionState.ciclos.length} ciclos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Lista o empty filtrado ──
          if (ciclosFiltrados.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list_off_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin resultados',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Probá ajustando los filtros o la búsqueda',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ciclo = ciclosFiltrados[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(
                              produccionNotifierProvider(
                                widget.productoraId,
                              ).notifier,
                            )
                            .seleccionarCiclo(ciclo);
                        _navigateToCicloForm(
                          ciclo.idLote,
                          ciclo.nombreLote,
                          produccionState.siguientePaso(ciclo.idLote),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: CicloTimeline(ciclo: ciclo),
                    ),
                  );
                }, childCount: ciclosFiltrados.length),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  FILTER CHIP
  // ═══════════════════════════════════════════════════════

  Widget _buildFilterChip(EstadoCiclo? estado, String label, IconData icon) {
    final isSelected = _filtroEstado == estado;
    final theme = Theme.of(context);

    Color chipColor;
    switch (estado) {
      case EstadoCiclo.abierto:
        chipColor = const Color(0xFF43A047);
      case EstadoCiclo.encintado:
        chipColor = const Color(0xFFFB8C00);
      case EstadoCiclo.cosechado:
        chipColor = const Color(0xFF1E88E5);
      default:
        chipColor = theme.colorScheme.primary;
    }

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : chipColor),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: chipColor.withValues(alpha: 0.08),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onSelected: (_) {
        setState(() {
          _filtroEstado = isSelected ? null : estado;
        });
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  //  DIALOGS & NAVIGATION
  // ═══════════════════════════════════════════════════════

  void _showCrearLoteDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final variedadCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Nuevo Lote', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextFormField(
                controller: nombreCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Lote',
                  hintText: 'Ej: Lote A-1',
                  prefixIcon: Icon(Icons.grass_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese el nombre';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: areaCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Área (manzanas)',
                  hintText: 'Ej: 2.5',
                  prefixIcon: Icon(Icons.square_foot_rounded),
                  suffixText: 'mz',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el área';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Área inválida';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: variedadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Variedad',
                  hintText: 'Ej: Cavendish, Williams...',
                  prefixIcon: Icon(Icons.eco_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingrese la variedad';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    ref
                        .read(
                          lotesNotifierProvider(widget.productoraId).notifier,
                        )
                        .crearLote(
                          nombre: nombreCtrl.text.trim(),
                          area: double.parse(areaCtrl.text),
                          variedad: variedadCtrl.text.trim(),
                        );
                    Navigator.pop(ctx);
                  }
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Crear Lote'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCicloForm(
    String idLote,
    String nombreLote,
    TipoEvento? siguientePaso,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CicloFormScreen(
          productoraId: widget.productoraId,
          idLote: idLote,
          nombreLote: nombreLote,
          siguientePaso: siguientePaso,
        ),
      ),
    );
  }
}
