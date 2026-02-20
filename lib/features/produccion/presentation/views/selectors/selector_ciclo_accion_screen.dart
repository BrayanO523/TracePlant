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
    final title = widget.tipoEvento == TipoEvento.encintado
        ? 'Seleccionar para Encintar'
        : 'Seleccionar para Cosechar';

    final mainDataAsync = _combineStreams();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              (_variedad != null ||
                      _finca != null ||
                      _cinta != null ||
                      _startDate != null)
                  ? Icons.filter_list_alt
                  : Icons.filter_list,
              color:
                  (_variedad != null ||
                      _finca != null ||
                      _cinta != null ||
                      _startDate != null)
                  ? AppColors.accent
                  : AppColors.textPrimary,
            ),
            onPressed: () {
              mainDataAsync.whenData((data) {
                _openFilters(data.variedades, data.nombresFincas, data.cintas);
              });
            },
          ),
          if (_searchQuery != null && _searchQuery!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search_off),
              onPressed: () {
                setState(() {
                  _searchQuery = null;
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
      body: mainDataAsync.when(
        data: (data) {
          var ciclos = data.ciclosFiltrados;

          // APLICAR FILTROS UI
          if (_searchQuery != null && _searchQuery!.isNotEmpty) {
            ciclos = ciclos
                .where(
                  (c) => c.nombreLote.toLowerCase().contains(_searchQuery!),
                )
                .toList();
          }
          if (_finca != null) {
            ciclos = ciclos.where((c) {
              final lote = data.lotesMap[c.idLote];
              final finca = lote != null ? data.fincasMap[lote.fincaId] : null;
              return finca?.nombre == _finca;
            }).toList();
          }
          if (_variedad != null) {
            ciclos = ciclos.where((c) => c.variedad == _variedad).toList();
          }
          if (_cinta != null) {
            ciclos = ciclos
                .where((c) => c.encintados.any((e) => e.cintaNombre == _cinta))
                .toList();
          }
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

          ciclos.sort((a, b) => a.fechaSiembra.compareTo(b.fechaSiembra));
          if (!_sortAscending) ciclos = ciclos.reversed.toList();

          if (ciclos.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${ciclos.length} lotes encontrados',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ciclos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ciclo = ciclos[index];
                    final lote = data.lotesMap[ciclo.idLote];
                    final finca = lote != null
                        ? data.fincasMap[lote.fincaId]
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
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.grass,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (finca != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.brown.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.brown.shade100,
                                        ),
                                      ),
                                      child: Text(
                                        finca.nombre.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown.shade700,
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
                            const Icon(Icons.chevron_right, color: Colors.grey),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
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
                if (mounted) {
                  setState(() {
                    _variedad = null;
                    _finca = null;
                    _cinta = null;
                    _searchQuery = null;
                    _searchController.clear();
                    _startDate = null;
                    _endDate = null;
                  });
                }
              },
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  AsyncValue<_SelectorData> _combineStreams() {
    final fincasAsync = ref.watch(
      fincasStreamProviderFamily(widget.productoraId),
    );
    final lotesAsync = ref.watch(
      lotesStreamProviderFamily(widget.productoraId),
    );
    final ciclosAsync = ref.watch(
      ciclosActivosStreamProviderFamily(widget.productoraId),
    );
    if (fincasAsync.isLoading || lotesAsync.isLoading || ciclosAsync.isLoading)
      return const AsyncValue.loading();
    if (fincasAsync.hasError)
      return AsyncValue.error(fincasAsync.error!, fincasAsync.stackTrace!);
    if (lotesAsync.hasError)
      return AsyncValue.error(lotesAsync.error!, lotesAsync.stackTrace!);
    if (ciclosAsync.hasError)
      return AsyncValue.error(ciclosAsync.error!, ciclosAsync.stackTrace!);

    final fincas = fincasAsync.value ?? <Finca>[];
    final lotes = lotesAsync.value ?? <Lote>[];
    final ciclos = ciclosAsync.value ?? <CicloProduccion>[];

    // Filtrar ciclos base
    final ciclosFiltrados = ciclos
        .where(
          (c) =>
              c.estado == EstadoCiclo.sembrado ||
              c.estado == EstadoCiclo.encintado,
        )
        .toList();

    final variedades =
        ciclosFiltrados
            .map((c) => c.variedad)
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
            .cast<String>()
          ..sort();
    final cintas =
        ciclosFiltrados
            .expand((c) => c.encintados.map((e) => e.cintaNombre))
            .toSet()
            .toList()
            .cast<String>()
          ..sort();
    final nombresFincas =
        fincas.map((f) => f.nombre).toSet().toList().cast<String>()..sort();

    final fincasMap = {for (var f in fincas) f.id: f};
    final lotesMap = {for (var l in lotes) l.id: l};

    return AsyncValue.data(
      _SelectorData(
        ciclosFiltrados: ciclosFiltrados,
        variedades: variedades,
        nombresFincas: nombresFincas,
        cintas: cintas,
        fincasMap: fincasMap,
        lotesMap: lotesMap,
      ),
    );
  }
}

class _SelectorData {
  final List<CicloProduccion> ciclosFiltrados;
  final List<String> variedades;
  final List<String> nombresFincas;
  final List<String> cintas;
  final Map<String, Finca> fincasMap;
  final Map<String, Lote> lotesMap;

  _SelectorData({
    required this.ciclosFiltrados,
    required this.variedades,
    required this.nombresFincas,
    required this.cintas,
    required this.fincasMap,
    required this.lotesMap,
  });
}
