import 'dart:async';
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
import '../../../../../../core/utils/formatters.dart';

// --- PROVEEDORES DE ESTADO LOCAL (BÚSQUEDA Y FILTROS) ---
final slsSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final slsVariedadProvider = StateProvider.autoDispose<String?>((ref) => null);
final slsFincaProvider = StateProvider.autoDispose<String?>((ref) => null);
final slsSortAscendingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

// --- PROVEEDOR DE DATOS COMBINADOS ---
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

final slsDataProvider = Provider.autoDispose
    .family<AsyncValue<_SelectorData>, String>((ref, productoraId) {
      final fincasAsync = ref.watch(fincasStreamProviderFamily(productoraId));
      final lotesAsync = ref.watch(lotesStreamProviderFamily(productoraId));
      final ciclosAsync = ref.watch(
        ciclosActivosStreamProviderFamily(productoraId),
      );

      if (fincasAsync.isLoading ||
          lotesAsync.isLoading ||
          ciclosAsync.isLoading) {
        return const AsyncValue.loading();
      }
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
      final nombresFincas = fincas.map((f) => f.nombre).toSet().toList()
        ..sort();
      final fincasMap = {for (var f in fincas) f.id: f};

      return AsyncValue.data(
        _SelectorData(
          lotesLibres: libres,
          variedades: variedades,
          nombresFincas: nombresFincas,
          fincasMap: fincasMap,
        ),
      );
    });

// --- PROVEEDOR DE IDS FILTRADOS ---
final slsFilteredLoteIdsProvider = Provider.autoDispose
    .family<AsyncValue<List<String>>, String>((ref, productoraId) {
      final dataAsync = ref.watch(slsDataProvider(productoraId));
      if (!dataAsync.hasValue) return const AsyncValue.loading();
      if (dataAsync.hasError)
        return AsyncValue.error(dataAsync.error!, dataAsync.stackTrace!);

      final data = dataAsync.value!;
      final searchQuery = ref.watch(slsSearchQueryProvider);
      final variedad = ref.watch(slsVariedadProvider);
      final finca = ref.watch(slsFincaProvider);
      final sortAsc = ref.watch(slsSortAscendingProvider);

      var lotes = data.lotesLibres;

      if (searchQuery.isNotEmpty) {
        lotes = lotes
            .where((l) => l.nombre.toLowerCase().contains(searchQuery))
            .toList();
      }
      if (variedad != null) {
        lotes = lotes.where((l) => l.variedad == variedad).toList();
      }
      if (finca != null) {
        final f = data.fincasMap.values.firstWhere(
          (fin) => fin.nombre == finca,
          orElse: () => Finca(
            id: '',
            nombre: '',
            productoraId: '',
            ubicacion: '',
            areaTotal: 0,
          ),
        );
        if (f.id.isNotEmpty)
          lotes = lotes.where((l) => l.fincaId == f.id).toList();
      }

      lotes.sort(
        (a, b) => sortAsc
            ? a.nombre.compareTo(b.nombre)
            : b.nombre.compareTo(a.nombre),
      );

      return AsyncValue.data(lotes.map((l) => l.id).toList());
    });

class SelectorLoteSiembraScreen extends ConsumerStatefulWidget {
  final String productoraId;
  const SelectorLoteSiembraScreen({super.key, required this.productoraId});

  @override
  ConsumerState<SelectorLoteSiembraScreen> createState() =>
      _SelectorLoteSiembraScreenState();
}

class _SelectorLoteSiembraScreenState
    extends ConsumerState<SelectorLoteSiembraScreen> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(slsSearchQueryProvider.notifier).state = val.toLowerCase();
    });
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
        sortAscending: ref.read(slsSortAscendingProvider),
        startDate: null,
        endDate: null,
        variedad: ref.read(slsVariedadProvider),
        finca: ref.read(slsFincaProvider),
        onApply:
            ({
              required sortAscending,
              startDate,
              endDate,
              variedad,
              cinta,
              finca,
            }) {
              ref.read(slsSortAscendingProvider.notifier).state = sortAscending;
              ref.read(slsVariedadProvider.notifier).state = variedad;
              ref.read(slsFincaProvider.notifier).state = finca;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredIdsAsync = ref.watch(
      slsFilteredLoteIdsProvider(widget.productoraId),
    );
    final dataAsync = ref.watch(slsDataProvider(widget.productoraId));

    final searchQuery = ref.watch(slsSearchQueryProvider);
    final variedad = ref.watch(slsVariedadProvider);
    final finca = ref.watch(slsFincaProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Seleccionar Lote',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              (variedad != null || finca != null)
                  ? Icons.filter_list_alt
                  : Icons.filter_list,
              color: (variedad != null || finca != null)
                  ? AppColors.accent
                  : AppColors.textPrimary,
            ),
            onPressed: () {
              dataAsync.whenData(
                (data) => _openFilters(data.variedades, data.nombresFincas),
              );
            },
          ),
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search_off),
              onPressed: () {
                _searchController.clear();
                ref.read(slsSearchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: filteredIdsAsync.when(
        data: (loteIds) {
          if (loteIds.isEmpty)
            return _buildEmptyState(variedad, finca, searchQuery);

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
                  onChanged: _onSearchChanged, // <-- Debouncer optimizado
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
                      '${AppFormatters.formatInt(loteIds.length)} lotes disponibles',
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
                  itemCount: loteIds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _LoteCard(
                      productoraId: widget.productoraId,
                      loteId: loteIds[index],
                      key: ValueKey(loteIds[index]),
                    ); // <-- Card Inteligente
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

  Widget _buildEmptyState(String? variedad, String? finca, String searchQuery) {
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
          if (variedad != null || finca != null || searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                ref.read(slsVariedadProvider.notifier).state = null;
                ref.read(slsFincaProvider.notifier).state = null;
                ref.read(slsSearchQueryProvider.notifier).state = '';
              },
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta inteligente que utiliza ref.select para evitar redibujos cuando otros lotes cambian.
class _LoteCard extends ConsumerWidget {
  final String productoraId;
  final String loteId;

  const _LoteCard({
    required this.productoraId,
    required this.loteId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loteModel = ref.watch(
      slsDataProvider(productoraId).select((dataAsync) {
        return dataAsync.valueOrNull?.lotesLibres.firstWhere(
          (l) => l.id == loteId,
        );
      }),
    );

    if (loteModel == null) return const SizedBox.shrink();

    final fincaNombre = ref.watch(
      slsDataProvider(productoraId).select((dataAsync) {
        return dataAsync.valueOrNull?.fincasMap[loteModel.fincaId]?.nombre ??
            '';
      }),
    );

    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CicloFormScreen(
              productoraId: productoraId,
              idLote: loteModel.id,
              nombreLote: loteModel.nombre,
              areaLote: loteModel.area,
              variedadLote: loteModel.variedad,
              siguientePaso: TipoEvento.siembra,
            ),
          ),
        );
      },
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.surfaceVariant,
          child: Icon(Icons.grid_on_rounded, color: AppColors.textSecondary),
        ),
        title: Text(
          loteModel.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$fincaNombre • ${AppFormatters.formatNumber(loteModel.area)} mz • ${loteModel.variedad}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
