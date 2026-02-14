import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/produccion_enums.dart'; // Import para EstadoLote
import '../widgets/lote_card.dart';
import 'ciclo_form_screen.dart';
import 'ciclo_history_screen.dart';

class ProduccionLotesScreen extends ConsumerStatefulWidget {
  final String productoraId;
  final String fincaId;
  final String fincaNombre;
  final bool readOnly;

  const ProduccionLotesScreen({
    super.key,
    required this.productoraId,
    required this.fincaId,
    required this.fincaNombre,
    this.readOnly = false,
  });

  @override
  ConsumerState<ProduccionLotesScreen> createState() =>
      _ProduccionLotesScreenState();
}

class _ProduccionLotesScreenState extends ConsumerState<ProduccionLotesScreen> {
  // Estado local para el filtro de chips
  EstadoLote? _filtroEstado; // null = Todos

  @override
  Widget build(BuildContext context) {
    final lotesState = ref.watch(lotesNotifierProvider(widget.productoraId));

    // Filtrar lotes por Finca y luego por Estado (Chip)
    final lotesDeFinca = lotesState.lotes.where((l) {
      if (l.fincaId != widget.fincaId) return false;
      if (_filtroEstado != null) {
        // Maper 'libre' a 'disponible' si es necesario, o exact match
        return l.estado == _filtroEstado;
      }
      return true;
    }).toList();

    // Trigger para cargar ciclos si no están cargados
    ref.watch(produccionNotifierProvider(widget.productoraId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header Moderno
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Lotes en ${widget.fincaNombre}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
              ),
            ),
          ),

          // 2. Filtros (Chips) - SliverToBoxAdapter
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sembrados', EstadoLote.ocupado),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Disponibles',
                      EstadoLote.libre,
                    ), // Usar libre/disponible según enum
                  ],
                ),
              ),
            ),
          ),

          // 3. Lista de Lotes (SliverList)
          if (lotesState.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (lotesState.error != null)
            SliverFillRemaining(
              child: Center(child: Text('Error: ${lotesState.error}')),
            )
          else if (lotesDeFinca.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _filtroEstado == null
                          ? 'No hay lotes'
                          : 'No hay lotes con este filtro',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final lote = lotesDeFinca[index];
                  return LoteCard(
                    lote: lote,
                    onTap: () {
                      if (widget.readOnly) {
                        // Modo Lectura
                        final produccionState = ref.read(
                          produccionNotifierProvider(widget.productoraId),
                        );
                        final ciclosLote = produccionState.ciclos
                            .where((c) => c.idLote == lote.id)
                            .toList();
                        if (ciclosLote.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CicloHistoryScreen(ciclo: ciclosLote.first),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sin historial activo'),
                            ),
                          );
                        }
                      } else {
                        // Modo Gestión
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              final siguiente = ref
                                  .read(
                                    produccionNotifierProvider(
                                      widget.productoraId,
                                    ),
                                  )
                                  .siguientePaso(lote.id);
                              return CicloFormScreen(
                                productoraId: widget.productoraId,
                                idLote: lote.id,
                                nombreLote: lote.nombre,
                                areaLote: lote.area,
                                variedadLote: lote.variedad,
                                siguientePaso: siguiente,
                              );
                            },
                          ),
                        );
                      }
                    },
                  );
                }, childCount: lotesDeFinca.length),
              ),
            ),

          // Espacio extra abajo
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, EstadoLote? estado) {
    final isSelected = _filtroEstado == estado;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _filtroEstado = selected ? estado : null;
          // Si deselecciona, vuelve a null (Todos).
          // Si selecciona 'Todos' (estado=null), también setea null.
          if (estado == null) _filtroEstado = null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}
