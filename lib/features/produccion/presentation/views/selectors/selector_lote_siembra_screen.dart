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
import '../../../domain/repositories/produccion_repository.dart';

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
    // 1. Obtener datos con Riverpod (Family Providers donde sea posible o Repository directo)
    final repo = ref.watch(produccionRepositoryProvider);

    // Usamos StreamProviders si existen (para caching) o repo directo.
    // Como creamos providers family, usémoslos para consistencia y caching.
    // Pero fincasStreamProvider NO es family aún? Ah, el usuario no lo pidió explicitamente pero
    // podemos usar repo.watchFincas directamente manejado com AsyncValue aqui.

    // (fincasAsync removed as it was unused and duplicated)

    final mainDataAsync = _combineStreams(repo);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Seleccionar Lote',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botón Filtros siempre visible (si hay datos cargados logicamente)
          IconButton(
            icon: Icon(
              (_variedad != null || _finca != null)
                  ? Icons.filter_list_alt
                  : Icons.filter_list,
              color: (_variedad != null || _finca != null)
                  ? AppColors.accent
                  : AppColors.textPrimary,
            ),
            onPressed: () {
              // Necesitamos los datos para abrir el modal.
              // Si aun cargando, tal vez no hacer nada o mostrar toast.
              mainDataAsync.whenData((data) {
                _openFilters(data.variedades, data.nombresFincas);
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
          var lotes = data.lotesLibres;

          // Filtrado en memoria
          if (_searchQuery != null && _searchQuery!.isNotEmpty) {
            lotes = lotes
                .where((l) => l.nombre.toLowerCase().contains(_searchQuery!))
                .toList();
          }
          if (_variedad != null) {
            lotes = lotes.where((l) => l.variedad == _variedad).toList();
          }
          if (_finca != null) {
            final fincaId = data.fincasMap.values
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
            if (fincaId.isNotEmpty)
              lotes = lotes.where((l) => l.fincaId == fincaId).toList();
          }

          lotes.sort((a, b) => a.nombre.compareTo(b.nombre));

          if (lotes.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar lote...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${lotes.length} lotes disponibles',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lotes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final lote = lotes[index];
                    final finca = data.fincasMap[lote.fincaId];
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
                          backgroundColor: AppColors.surfaceVariant,
                          child: Icon(
                            Icons.grid_on_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        title: Text(
                          lote.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${finca?.nombre ?? ''} • ${lote.area} mz • ${lote.variedad}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
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

  // Helper para combinar streams
  AsyncValue<_SelectorData> _combineStreams(ProduccionRepository repo) {
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

    final ocupados = ciclos.map((c) => c.idLote).toSet();
    final libres = lotes.where((l) => !ocupados.contains(l.id)).toList();

    final variedades =
        libres
            .map((l) => l.variedad)
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final nombresFincas = fincas.map((f) => f.nombre).toSet().toList()..sort();
    final fincasMap = {for (var f in fincas) f.id: f};

    return AsyncValue.data(
      _SelectorData(
        lotesLibres: libres,
        variedades: variedades,
        nombresFincas: nombresFincas,
        fincasMap: fincasMap,
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
                if (mounted) {
                  setState(() {
                    _variedad = null;
                    _finca = null;
                    _searchQuery = null;
                    _searchController.clear();
                  });
                }
              },
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }
}

class _SelectorData {
  final List<Lote> lotesLibres;
  final List<String> variedades;
  final List<String> nombresFincas;
  final Map<String, Finca> fincasMap;

  _SelectorData({
    required this.lotesLibres,
    required this.variedades,
    required this.nombresFincas,
    required this.fincasMap,
  });
}
