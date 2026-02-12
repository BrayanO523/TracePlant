import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../empacadora/domain/entities/empacadora.dart'; // Import Empacadora
import '../viewmodels/asignaciones_notifier.dart';
import '../widgets/empacadora_selection_dialog.dart'; // Import dialog
import '../widgets/productora_assignment_card.dart';
import '../widgets/relaciones_map.dart';

/// Panel de Administración — Dashboard de Asignación de Suministros.
///
/// Diseño Rediseñado (Master-Detail integrado):
/// - Selector de Empacadora arriba.
/// - Lista de Productoras abajo con detalle de lotes.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = ''; // Nueva variable de estado para búsqueda
  final Set<String> _selectedProductoraIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            backgroundColor: const Color(0xFF43A047),
          ),
        );
        ref.read(asignacionesNotifierProvider.notifier).clearMessages();
        setState(() {
          _selectedProductoraIds.clear();
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
                  onPressed: () {
                    ref.read(asignacionesNotifierProvider.notifier).refresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
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
                children: [
                  _buildAsignarTab(state),
                  RelacionesMap(
                    state: state,
                    onDesasignar: (id) => _showDesasignarDialog(context, id),
                  ),
                ],
              ),
      ),
      floatingActionButton:
          _tabController.index == 0 && _selectedProductoraIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: state.isLoading
                  ? null
                  : () => _confirmarAsignacion(state),
              icon: const Icon(Icons.send_rounded),
              label: Text('Asignar ${_selectedProductoraIds.length}'),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB ASIGNAR (REDISEÑADO)
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  //  TAB ASIGNAR (REDISEÑADO + ESCALABLE)
  // ═══════════════════════════════════════════════════════

  Widget _buildAsignarTab(AsignacionesState state) {
    // 1. Filtrado Local
    final filteredProductoras = state.productorasDisponibles.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          (p.location?.toLowerCase().contains(query) ?? false);
    }).toList();

    final allSelected =
        filteredProductoras.isNotEmpty &&
        filteredProductoras.every((p) => _selectedProductoraIds.contains(p.id));

    return CustomScrollView(
      slivers: [
        // 1. Buscador + Acciones Masivas (Sticky Header)
        SliverAppBar(
          pinned: true,
          floating: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          flexibleSpace: Padding(
            padding: const EdgeInsets.all(16.0),
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
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Seleccionar Todo
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
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

        // 2. Título y Contador
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  'Productoras Disponibles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredProductoras.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Lista Filtrada
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
                final isSelected = _selectedProductoraIds.contains(
                  productora.id,
                );
                final lotes = state.lotesPorProductora[productora.id] ?? [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductoraAssignmentCard(
                    productora: productora,
                    lotes: lotes,
                    isSelected: isSelected,
                    onSelectionChanged: (value) {
                      setState(() {
                        if (value) {
                          _selectedProductoraIds.add(productora.id);
                        } else {
                          _selectedProductoraIds.remove(productora.id);
                        }
                      });
                    },
                  ),
                );
              }, childCount: filteredProductoras.length),
            ),
          ),
      ],
    );
  }

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

  Future<void> _confirmarAsignacion(AsignacionesState state) async {
    if (_selectedProductoraIds.isEmpty) return;

    // 1. Abrir Modal de Selección de Empacadora
    final selectedEmpacadora = await showDialog<Empacadora>(
      context: context,
      builder: (ctx) => EmpacadoraSelectionDialog(
        empacadoras: state.empacadoras,
        cargaTrabajo: state.cargaTrabajo,
      ),
    );

    if (selectedEmpacadora == null) return; // Cancelado

    // 2. Ejecutar Asignación Batch
    ref
        .read(asignacionesNotifierProvider.notifier)
        .asignarBatch(
          idEmpacadora: selectedEmpacadora.id,
          idsProductoras: _selectedProductoraIds.toList(),
        );
  }

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
