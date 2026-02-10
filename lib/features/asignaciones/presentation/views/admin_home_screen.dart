import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../viewmodels/asignaciones_notifier.dart';
import '../widgets/empacadora_selector.dart';
import '../widgets/relaciones_map.dart';
import '../../../productora/domain/entities/productora.dart';

/// Panel de Administración — Dashboard de Asignación de Suministros.
///
/// Permite al Admin vincular Productoras a Empacadoras y ver un mapa
/// de relaciones resumido.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedEmpacadoraId;
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

    // Escuchar mensajes de éxito / error
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
        // Limpiar selección UI
        setState(() {
          _selectedProductoraIds.clear();
          _selectedEmpacadoraId = null;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.link_rounded), text: 'Asignar'),
            Tab(icon: Icon(Icons.account_tree_rounded), text: 'Relaciones'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar datos',
            onPressed: () {
              ref.read(asignacionesNotifierProvider.notifier).refresh();
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: state.isLoading && state.asignaciones.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAsignarTab(state, theme),
                RelacionesMap(
                  state: state,
                  onDesasignar: (idAsignacion) {
                    _showDesasignarDialog(context, idAsignacion);
                  },
                ),
              ],
            ),
      floatingActionButton:
          _tabController.index == 0 &&
              _selectedEmpacadoraId != null &&
              _selectedProductoraIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: state.isLoading ? null : _confirmarAsignacion,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                'Asignar ${_selectedProductoraIds.length} productora(s)',
              ),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB ASIGNAR
  // ═══════════════════════════════════════════════════════

  Widget _buildAsignarTab(AsignacionesState state, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(asignacionesNotifierProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Paso 1: Seleccionar Empacadora ──
          _buildSectionHeader(
            theme,
            icon: Icons.business_rounded,
            title: 'Paso 1: Seleccionar Empacadora',
            subtitle: 'Elige la empacadora que recibirá productoras',
          ),
          const SizedBox(height: 12),

          EmpacadoraSelector(
            empacadoras: state.empacadoras,
            cargaTrabajo: state.cargaTrabajo,
            selectedId: _selectedEmpacadoraId,
            onChanged: (id) {
              setState(() {
                _selectedEmpacadoraId = id;
                _selectedProductoraIds.clear();
              });
            },
          ),

          const SizedBox(height: 28),

          // ── Paso 2: Seleccionar Productoras ──
          _buildSectionHeader(
            theme,
            icon: Icons.agriculture_rounded,
            title: 'Paso 2: Seleccionar Productoras',
            subtitle: _selectedEmpacadoraId == null
                ? 'Primero selecciona una empacadora'
                : '${state.productorasDisponibles.length} disponibles',
          ),
          const SizedBox(height: 12),

          if (_selectedEmpacadoraId == null)
            _buildEmptyState(
              theme,
              icon: Icons.touch_app_rounded,
              message: 'Selecciona una empacadora arriba para continuar',
            )
          else if (state.productorasDisponibles.isEmpty)
            _buildEmptyState(
              theme,
              icon: Icons.check_circle_outline_rounded,
              message: 'Todas las productoras ya están asignadas',
            )
          else
            ..._buildProductorasList(state.productorasDisponibles, theme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProductorasList(
    List<Productora> productoras,
    ThemeData theme,
  ) {
    return productoras.map((p) {
      final isSelected = _selectedProductoraIds.contains(p.id);
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (_) {
              setState(() {
                if (isSelected) {
                  _selectedProductoraIds.remove(p.id);
                } else {
                  _selectedProductoraIds.add(p.id);
                }
              });
            },
            title: Text(
              p.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            subtitle: Text(
              p.location ?? 'Sin ubicación',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            secondary: CircleAvatar(
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.agriculture_rounded,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState(
    ThemeData theme, {
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ACCIONES
  // ═══════════════════════════════════════════════════════

  void _confirmarAsignacion() {
    if (_selectedEmpacadoraId == null || _selectedProductoraIds.isEmpty) return;

    ref
        .read(asignacionesNotifierProvider.notifier)
        .asignarBatch(
          idEmpacadora: _selectedEmpacadoraId!,
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
