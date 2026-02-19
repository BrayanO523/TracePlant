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

class SelectorCicloAccionScreen extends ConsumerStatefulWidget {
  final String productoraId;
  final TipoEvento tipoEvento; // encintado o cosecha

  const SelectorCicloAccionScreen({
    super.key,
    required this.productoraId,
    required this.tipoEvento,
  });

  @override
  ConsumerState<SelectorCicloAccionScreen> createState() =>
      _SelectorCicloAccionScreenState();
}

class _SelectorCicloAccionScreenState
    extends ConsumerState<SelectorCicloAccionScreen> {
  bool _sortAscending = false; // Más reciente por defecto
  DateTime? _startDate;
  DateTime? _endDate;
  String? _variedad;
  String? _finca;
  String? _cinta;
  String? _searchQuery;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters(
    List<String> variedades,
    List<String> fincas,
    List<String> cintas,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectorFilterModal(
        variedades: variedades,
        cintas: cintas,
        fincas: fincas,
        sortAscending: _sortAscending,
        startDate: _startDate,
        endDate: _endDate,
        variedad: _variedad,
        cinta: _cinta,
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
                _cinta = cinta;
                _finca = finca;
              });
            },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(produccionRepositoryProvider);
    final title = widget.tipoEvento == TipoEvento.encintado
        ? 'Seleccionar para Encintar'
        : 'Seleccionar para Cosechar';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_variedad != null ||
              _finca != null ||
              _cinta != null ||
              _startDate != null)
            IconButton(
              icon: const Icon(
                Icons.filter_list_off_rounded,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  _variedad = null;
                  _finca = null;
                  _cinta = null;
                  _startDate = null;
                  _endDate = null;
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

                return StreamBuilder<List<Lote>>(
                  stream: repo.watchLotes(widget.productoraId),
                  builder: (context, lotesSnap) {
                    if (!lotesSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lotes = lotesSnap.data!;
                    final mapLotes = {for (var l in lotes) l.id: l};

                    return StreamBuilder<List<CicloProduccion>>(
                      stream: repo.watchCiclosActivos(widget.productoraId),
                      builder: (context, ciclosSnap) {
                        if (!ciclosSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var ciclos = ciclosSnap.data!;

                        // Filtrar solo relevantes para la acción
                        // Si es Encintado/Cosecha mostramos todo lo activo (sembrado o encintado)
                        // Aunque para Cosechar normalmente se requiere estar Encintado,
                        // el usuario pidió flexibilidad antes ("Cosechar desde Sembrado").
                        ciclos = ciclos
                            .where(
                              (c) =>
                                  c.estado == EstadoCiclo.sembrado ||
                                  c.estado == EstadoCiclo.encintado,
                            )
                            .toList();

                        // Extraer metadatos para filtros
                        final variedades =
                            ciclos
                                .map((c) => c.variedad)
                                .where((v) => v.isNotEmpty)
                                .toSet()
                                .toList()
                                .cast<String>()
                              ..sort();

                        final cintas =
                            ciclos
                                .expand(
                                  (c) => c.encintados.map((e) => e.cintaNombre),
                                )
                                .toSet()
                                .toList()
                                .cast<String>()
                              ..sort();

                        // APLICAR FILTROS

                        // 1. Busqueda texto
                        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
                          ciclos = ciclos
                              .where(
                                (c) => c.nombreLote.toLowerCase().contains(
                                  _searchQuery!,
                                ),
                              )
                              .toList();
                        }

                        // 2. Finca
                        if (_finca != null) {
                          ciclos = ciclos.where((c) {
                            final lote = mapLotes[c.idLote];
                            if (lote == null) return false;
                            final finca = mapFincas[lote.fincaId];
                            return finca?.nombre == _finca;
                          }).toList();
                        }

                        // 3. Variedad
                        if (_variedad != null) {
                          ciclos = ciclos
                              .where((c) => c.variedad == _variedad)
                              .toList();
                        }

                        // 4. Cinta (Solo si tiene encintados con ese color)
                        if (_cinta != null) {
                          ciclos = ciclos
                              .where(
                                (c) => c.encintados.any(
                                  (e) => e.cintaNombre == _cinta,
                                ),
                              )
                              .toList();
                        }

                        // 5. Fechas (Filtro por fecha de siembra)
                        if (_startDate != null) {
                          ciclos = ciclos
                              .where(
                                (c) =>
                                    c.fechaSiembra.isAfter(_startDate!) ||
                                    isSameDay(c.fechaSiembra, _startDate!),
                              )
                              .toList();
                        }
                        if (_endDate != null) {
                          ciclos = ciclos
                              .where(
                                (c) =>
                                    c.fechaSiembra.isBefore(_endDate!) ||
                                    isSameDay(c.fechaSiembra, _endDate!),
                              )
                              .toList();
                        }

                        // Ordenamiento
                        ciclos.sort(
                          (a, b) => a.fechaSiembra.compareTo(b.fechaSiembra),
                        );
                        if (!_sortAscending) {
                          ciclos = ciclos.reversed.toList();
                        }

                        if (ciclos.isEmpty) return _buildEmptyState();

                        return Column(
                          children: [
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
                                    '${ciclos.length} lotes encontrados',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _openFilters(
                                      variedades,
                                      listaNombresFincas,
                                      cintas,
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
                                itemCount: ciclos.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final ciclo = ciclos[index];
                                  final lote = mapLotes[ciclo.idLote];
                                  final finca = lote != null
                                      ? mapFincas[lote.fincaId]
                                      : null;

                                  return InkWell(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CicloFormScreen(
                                            productoraId: widget.productoraId,
                                            idLote: ciclo.idLote,
                                            nombreLote: ciclo.nombreLote,
                                            siguientePaso: widget.tipoEvento,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            child: const Icon(
                                              Icons.grass,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (finca != null)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.brown.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors
                                                            .brown
                                                            .shade100,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      finca.nombre
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .brown
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  ciclo.nombreLote,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Sembrado el ${_formatDate(ciclo.fechaSiembra)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                          ),
                                        ],
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

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron resultados',
            style: TextStyle(color: Colors.grey),
          ),
          if (_variedad != null || _finca != null || _searchQuery != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _variedad = null;
                  _finca = null;
                  _cinta = null;
                  _searchQuery = null;
                  _searchController.clear();
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }
}
