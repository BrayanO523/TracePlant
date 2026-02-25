import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../viewmodels/asignaciones_notifier.dart';
import '../widgets/productora_stats_card.dart';
import '../widgets/relaciones_map.dart';
import '../../../../core/utils/formatters.dart';

/// Panel de Administración — Dashboard de Asignación de Suministros.
///
/// Lógica: A cada Empacadora se le asignan 1..N Productoras.
///
/// Diseño optimizado para muchas productoras/empacadoras:
/// - KPI Strip con métricas rápidas
/// - Lista con búsqueda + selección masiva + stats on-demand
/// - Tab Relaciones con búsqueda
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _relacionesSearchQuery = '';
  final Set<String> _selectedProductoraIds = {};

  // Flujo: 0 = Empacadoras, 1 = Productoras
  int _activeView = 0;
  String? _selectedEmpacadoraId;
  String? _selectedEmpacadoraName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(asignacionesNotifierProvider);
    final theme = Theme.of(context);

    // Listeners para mensajes
    ref.listen<AsignacionesState>(asignacionesNotifierProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(asignacionesNotifierProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(next.successMessage!),
              ],
            ),
            backgroundColor: AppColors.estadoCosechado,
          ),
        );
        ref.read(asignacionesNotifierProvider.notifier).clearMessages();
        setState(() {
          _selectedProductoraIds.clear();
          _selectedEmpacadoraId = null;
          _selectedEmpacadoraName = null;
          _activeView = 0;
        });
      }
    });

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Panel de Asignación'),
              centerTitle: true,
              pinned: true,
              floating: true,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.link_rounded), text: 'Asignar'),
                  Tab(
                    icon: Icon(Icons.account_tree_rounded),
                    text: 'Relaciones',
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar datos',
                  onPressed: () {
                    ref.read(asignacionesNotifierProvider.notifier).refresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Cerrar sesión',
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ];
        },
        body: state.isLoading && state.empacadoras.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [_buildAsignarTab(state), _buildRelacionesTab(state)],
              ),
      ),
      // FAB solo en vista de productoras con empacadora seleccionada
      floatingActionButton:
          _tabController.index == 0 &&
              _activeView == 1 &&
              _selectedEmpacadoraId != null &&
              _selectedProductoraIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: state.isLoading
                  ? null
                  : () {
                      ref
                          .read(asignacionesNotifierProvider.notifier)
                          .asignarBatch(
                            idEmpacadora: _selectedEmpacadoraId!,
                            idsProductoras: _selectedProductoraIds.toList(),
                          );
                    },
              icon: const Icon(Icons.send_rounded),
              label: Text(
                'Asignar ${_selectedProductoraIds.length} a $_selectedEmpacadoraName',
              ),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  KPI STRIP
  // ═══════════════════════════════════════════════════════

  Widget _buildKpiStrip(AsignacionesState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Botón Empacadoras (Paso 1)
          Expanded(
            child: _KpiButton(
              icon: Icons.business_rounded,
              label: 'Empacadoras',
              value: AppFormatters.formatInt(state.empacadoras.length),
              color: Colors.blue,
              isActive: _activeView == 0,
              badge: _selectedEmpacadoraId != null ? '✓' : null,
              onTap: () => setState(() {
                _activeView = 0;
                _searchQuery = '';
              }),
            ),
          ),
          const SizedBox(width: 8),
          // Botón Productoras (Paso 2)
          Expanded(
            child: _KpiButton(
              icon: Icons.agriculture_rounded,
              label: 'Disponibles',
              value: AppFormatters.formatInt(
                state.productorasDisponibles.length,
              ),
              color: AppColors.estadoCosechado,
              isActive: _activeView == 1,
              badge: _selectedProductoraIds.isNotEmpty
                  ? '${_selectedProductoraIds.length}'
                  : null,
              onTap: () {
                if (_selectedEmpacadoraId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Primero selecciona una empacadora'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() {
                  _activeView = 1;
                  _searchQuery = '';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Asignaciones (solo informativo)
          Expanded(
            child: _KpiButton(
              icon: Icons.link_rounded,
              label: 'Asignaciones',
              value: AppFormatters.formatInt(state.totalAsignaciones),
              color: Colors.deepPurple,
              isActive: false,
              onTap: () {
                // Cambiar a tab Relaciones para ver asignaciones
                _tabController.animateTo(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB ASIGNAR
  // ═══════════════════════════════════════════════════════

  Widget _buildAsignarTab(AsignacionesState state) {
    return CustomScrollView(
      slivers: [
        // 1. KPI Strip (ahora son botones)
        SliverToBoxAdapter(child: _buildKpiStrip(state)),

        // 2. Banner de empacadora seleccionada (si hay una)
        if (_selectedEmpacadoraId != null && _activeView == 1)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.business_rounded,
                    size: 18,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asignando a: $_selectedEmpacadoraName',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _selectedEmpacadoraId = null;
                      _selectedEmpacadoraName = null;
                      _selectedProductoraIds.clear();
                      _activeView = 0;
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. Contenido dinámico según vista activa
        if (_activeView == 0)
          ..._buildEmpacadorasView(state)
        else
          ..._buildProductorasView(state),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  VISTA: EMPACADORAS (Paso 1)
  // ═══════════════════════════════════════════════════════

  List<Widget> _buildEmpacadorasView(AsignacionesState state) {
    final filtered = state.empacadoras.where((e) {
      final query = _searchQuery.toLowerCase();
      return e.name.toLowerCase().contains(query) ||
          (e.location?.toLowerCase().contains(query) ?? false);
    }).toList();

    return [
      // Buscador
      SliverAppBar(
        pinned: true,
        floating: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar empacadora...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
          ),
        ),
      ),

      // Título
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Paso 1: Selecciona una empacadora',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),

      // Lista de empacadoras
      if (filtered.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            Icons.search_off_rounded,
            'No se encontraron empacadoras',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final emp = filtered[index];
              final carga = state.cargaTrabajo[emp.id] ?? 0;
              final isSelected = _selectedEmpacadoraId == emp.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.08)
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _selectedEmpacadoraId = emp.id;
                        _selectedEmpacadoraName = emp.name;
                        _activeView = 1;
                        _searchQuery = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Theme.of(context).colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.blue
                                : Colors.blue.withValues(alpha: 0.1),
                            child: Text(
                              emp.name[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.name,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${emp.location ?? "Sin ubicación"} • $carga asignada${carga != 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Check
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.blue,
                              size: 24,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: filtered.length),
          ),
        ),
    ];
  }

  // ═══════════════════════════════════════════════════════
  //  VISTA: PRODUCTORAS (Paso 2)
  // ═══════════════════════════════════════════════════════

  List<Widget> _buildProductorasView(AsignacionesState state) {
    final filteredProductoras = state.productorasDisponibles.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          (p.location?.toLowerCase().contains(query) ?? false) ||
          (p.rnt?.toLowerCase().contains(query) ?? false) ||
          (p.code?.toLowerCase().contains(query) ?? false);
    }).toList();

    final allSelected =
        filteredProductoras.isNotEmpty &&
        filteredProductoras.every((p) => _selectedProductoraIds.contains(p.id));

    return [
      // Buscador + Seleccionar Todo
      SliverAppBar(
        pinned: true,
        floating: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar productora...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    if (allSelected) {
                      _selectedProductoraIds.clear();
                    } else {
                      _selectedProductoraIds.addAll(
                        filteredProductoras.map((p) => p.id),
                      );
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: allSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: allSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    allSelected
                        ? Icons.library_add_check_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: allSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Título + Contador
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Text(
                'Paso 2: Selecciona productoras',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredProductoras.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (_selectedProductoraIds.isNotEmpty) ...[
                const Spacer(),
                Text(
                  '${_selectedProductoraIds.length} seleccionadas',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // Lista de productoras
      if (state.productorasDisponibles.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            Icons.check_circle_outline_rounded,
            '¡Todo asignado! No hay productoras pendientes.',
          ),
        )
      else if (filteredProductoras.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            Icons.search_off_rounded,
            'No se encontraron productoras con "$_searchQuery"',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final productora = filteredProductoras[index];
              final isSelected = _selectedProductoraIds.contains(productora.id);

              return ProductoraStatsCard(
                productora: productora,
                isSelected: isSelected,
                onSelectionChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedProductoraIds.add(productora.id);
                    } else {
                      _selectedProductoraIds.remove(productora.id);
                    }
                  });
                },
              );
            }, childCount: filteredProductoras.length),
          ),
        ),
    ];
  }

  // ═══════════════════════════════════════════════════════
  //  TAB RELACIONES (CON BÚSQUEDA)
  // ═══════════════════════════════════════════════════════

  Widget _buildRelacionesTab(AsignacionesState state) {
    return Column(
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) =>
                setState(() => _relacionesSearchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar empacadora o productora...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _relacionesSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () =>
                          setState(() => _relacionesSearchQuery = ''),
                    )
                  : null,
            ),
          ),
        ),
        // Mapa de Relaciones
        Expanded(
          child: RelacionesMap(
            state: state,
            searchQuery: _relacionesSearchQuery,
            onDesasignar: (id) => _showDesasignarDialog(context, id),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════

  Widget _buildEmptyState(IconData icon, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ACCIONES
  // ═══════════════════════════════════════════════════════

  void _showDesasignarDialog(BuildContext context, String idAsignacion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Desasignar productora?'),
        content: const Text(
          'La productora quedará libre para ser asignada a otra empacadora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(asignacionesNotifierProvider.notifier)
                  .desasignar(idAsignacion);
            },
            child: const Text('Desasignar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  KPI CARD WIDGET
// ═══════════════════════════════════════════════════════

class _KpiButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _KpiButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? color : theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
