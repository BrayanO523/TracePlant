import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/di/providers.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../administracion/domain/entities/finca.dart';
import '../../../domain/entities/ciclo_produccion.dart';
import '../../../domain/entities/lote.dart';
import '../../../domain/entities/produccion_enums.dart';
import '../ciclo_form_screen.dart';
import 'selector_filter_modal.dart';

class SelectorLoteSiembraScreen extends ConsumerStatefulWidget {
  final String productoraId;

  const SelectorLoteSiembraScreen({super.key, required this.productoraId});

  @override
  ConsumerState<SelectorLoteSiembraScreen> createState() =>
      _SelectorLoteSiembraScreenState();
}

class _SelectorLoteSiembraScreenState
    extends ConsumerState<SelectorLoteSiembraScreen> {
  // Estado local de filtros
  bool _sortAscending =
      false; // true: A-Z, false: Z-A (por nombre lote por defecto)
  DateTime?
  _startDate; // No aplica mucho para lotes libres, pero lo dejamos por si acaso (ej. fecha creación?)
  DateTime? _endDate;
  String? _variedad;
  String? _finca;
  String? _searchQuery;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters(List<String> variedades, List<String> fincas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectorFilterModal(
        variedades: variedades,
        cintas: const [], // Lotes libre no tienen cinta
        fincas: fincas,
        sortAscending: _sortAscending,
        startDate: _startDate,
        endDate: _endDate,
        variedad: _variedad,
        finca: _finca,
        onApply:
            ({
              required sortAscending,
              startDate,
              endDate,
              variedad,
              cinta,
              finca,
            }) {
              setState(() {
                _sortAscending = sortAscending;
                _startDate = startDate;
                _endDate = endDate;
                _variedad = variedad;
                _finca = finca;
              });
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(produccionRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Seleccionar Lote',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Clear filters button if any active
          if (_variedad != null || _finca != null)
            IconButton(
              icon: const Icon(
                Icons.filter_list_off_rounded,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  _variedad = null;
                  _finca = null;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar lote...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Finca>>(
              stream: repo.watchFincas(widget.productoraId),
              builder: (context, fincasSnap) {
                if (!fincasSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final fincas = fincasSnap.data!;
                final mapFincas = {for (var f in fincas) f.id: f};
                final listaNombresFincas =
                    fincas.map((f) => f.nombre).toSet().toList()..sort();

                return StreamBuilder<List<CicloProduccion>>(
                  stream: repo.watchCiclosActivos(widget.productoraId),
                  builder: (context, ciclosSnap) {
                    if (!ciclosSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final ciclosActivos = ciclosSnap.data!;
                    final lotesOcupadosIds = ciclosActivos
                        .map((c) => c.idLote)
                        .toSet();

                    return StreamBuilder<List<Lote>>(
                      stream: repo.watchLotes(widget.productoraId),
                      builder: (context, lotesSnap) {
                        if (!lotesSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var lotes = lotesSnap.data!;

                        // Extraer opciones para filtros
                        final variedades =
                            lotes
                                .map((l) => l.variedad)
                                .where((v) => v.isNotEmpty)
                                .toSet()
                                .toList()
                              ..sort();

                        // FILTRADO
                        // 1. Libres
                        lotes = lotes.where((lote) {
                          return !lotesOcupadosIds.contains(lote.id);
                        }).toList();

                        // 2. Filtros UI
                        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
                          lotes = lotes
                              .where(
                                (l) => l.nombre.toLowerCase().contains(
                                  _searchQuery!,
                                ),
                              )
                              .toList();
                        }

                        if (_variedad != null) {
                          lotes = lotes
                              .where((l) => l.variedad == _variedad)
                              .toList();
                        }

                        if (_finca != null) {
                          // Buscar ID de finca por nombre
                          final fincaId = fincas
                              .firstWhere(
                                (f) => f.nombre == _finca,
                                orElse: () => Finca(
                                  id: '',
                                  nombre: '',
                                  productoraId: '',
                                  ubicacion: '',
                                  areaTotal: 0,
                                ),
                              )
                              .id;
                          if (fincaId.isNotEmpty) {
                            lotes = lotes
                                .where((l) => l.fincaId == fincaId)
                                .toList();
                          }
                        }

                        // 3. Ordenamiento (Alfabetico por defecto)
                        lotes.sort((a, b) => a.nombre.compareTo(b.nombre));
                        if (!_sortAscending) {
                          // Revertir si el usuario eligió "Más Antiguos" (aca reusamos el bool para A-Z o Z-A)
                          // Nota: En el modal dice "Más Recientes" vs "Más Antiguos", eso aplica a fechas.
                          // Para lotes sin fecha, podríamos interpretar Ascending como A-Z.
                          // Si el usuario pone "Más antiguos", podríamos invertir.
                          // Dejemoslo simple: A-Z siempre, a menos que se implemente fecha creación.
                        }

                        if (lotes.isEmpty) {
                          return _buildEmptyState();
                        }

                        return Column(
                          children: [
                            // Filter Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${lotes.length} lotes disponibles',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _openFilters(
                                      variedades,
                                      listaNombresFincas,
                                    ),
                                    icon: const Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Filtros'),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: lotes.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final lote = lotes[index];
                                  final finca = mapFincas[lote.fincaId];

                                  return InkWell(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CicloFormScreen(
                                            productoraId: widget.productoraId,
                                            idLote: lote.id,
                                            nombreLote: lote.nombre,
                                            areaLote: lote.area,
                                            variedadLote: lote.variedad,
                                            siguientePaso: TipoEvento.siembra,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor:
                                            AppColors.surfaceVariant,
                                        child: Icon(
                                          Icons.grid_on_rounded,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      title: Text(
                                        lote.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (finca != null)
                                            Text(
                                              finca.nombre.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.brown.shade600,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          Text(
                                            '${lote.area} mz • ${lote.variedad}',
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron lotes',
            style: TextStyle(color: Colors.grey),
          ),
          if (_variedad != null || _finca != null || _searchQuery != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _variedad = null;
                  _finca = null;
                  _searchQuery = null;
                  _searchController.clear();
                });
              },
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }
}
