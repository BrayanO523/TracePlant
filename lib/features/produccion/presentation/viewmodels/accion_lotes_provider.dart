import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../administracion/domain/entities/finca.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';
import '../../domain/entities/tipo_accion_produccion.dart';
import 'production_fincas_notifier.dart';

class FincaConLotesAccion {
  final Finca finca;
  final List<Lote> lotesDisponibles;

  /// Mapa opcional que asocia un loteId con su Ciclo activo actual (necesario para Encintado/Cosecha)
  final Map<String, CicloProduccion> ciclosPorLote;

  const FincaConLotesAccion({
    required this.finca,
    required this.lotesDisponibles,
    this.ciclosPorLote = const {},
  });

  bool get hasLotes => lotesDisponibles.isNotEmpty;
  int get count => lotesDisponibles.length;
}

final _lotesStreamProv = StreamProvider.family<List<Lote>, String>((
  ref,
  productoraId,
) {
  return ref.watch(produccionRepositoryProvider).watchLotes(productoraId);
});

final _ciclosActivosStreamProv =
    StreamProvider.family<List<CicloProduccion>, String>((ref, productoraId) {
      return ref
          .watch(produccionRepositoryProvider)
          .watchCiclosActivos(productoraId);
    });

class AccionProduccionParams {
  final String productoraId;
  final TipoAccionProduccion accion;

  const AccionProduccionParams(this.productoraId, this.accion);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccionProduccionParams &&
          runtimeType == other.runtimeType &&
          productoraId == other.productoraId &&
          accion == other.accion;

  @override
  int get hashCode => productoraId.hashCode ^ accion.hashCode;
}

final accionFincasProvider =
    Provider.family<
      AsyncValue<List<FincaConLotesAccion>>,
      AccionProduccionParams
    >((ref, params) {
      final fincasState = ref.watch(
        productionFincasProvider(params.productoraId),
      );
      final lotesAsync = ref.watch(_lotesStreamProv(params.productoraId));
      final ciclosAsync = ref.watch(
        _ciclosActivosStreamProv(params.productoraId),
      );

      if (fincasState.isLoading ||
          lotesAsync.isLoading ||
          ciclosAsync.isLoading) {
        return const AsyncValue.loading();
      }

      if (fincasState.error != null)
        return AsyncValue.error(fincasState.error!, StackTrace.current);
      if (lotesAsync.hasError)
        return AsyncValue.error(lotesAsync.error!, lotesAsync.stackTrace!);
      if (ciclosAsync.hasError)
        return AsyncValue.error(ciclosAsync.error!, ciclosAsync.stackTrace!);

      final fincas = fincasState.fincas;
      final lotes = lotesAsync.value ?? [];
      final ciclos = ciclosAsync.value ?? [];

      final List<FincaConLotesAccion> result = [];

      for (final finca in fincas) {
        final lotesDeFinca = lotes.where((l) => l.fincaId == finca.id).toList();
        final List<Lote> disponibles = [];
        final Map<String, CicloProduccion> ciclosAsociados = {};

        for (final lote in lotesDeFinca) {
          if (params.accion == TipoAccionProduccion.siembra) {
            // Para sembrar, el lote debe estar libre
            if (lote.estado == EstadoLote.libre) {
              disponibles.add(lote);
            }
          } else {
            // Para encintar o cosechar, el lote debe estar Ocupado y tener un ciclo activo válido.
            if (lote.estado == EstadoLote.ocupado) {
              // Buscar si el lote tiene un ciclo en estado sembrado o encintado
              try {
                final ciclo = ciclos.firstWhere(
                  (c) =>
                      c.idLote == lote.id &&
                      (c.estado == EstadoCiclo.sembrado ||
                          c.estado == EstadoCiclo.encintado),
                );
                disponibles.add(lote);
                ciclosAsociados[lote.id] = ciclo;
              } catch (_) {
                // No se encontró ciclo válido, el lote no aplica para la tarea o está en otro estado (abierto/etc)
              }
            }
          }
        }

        // Solo agregamos la finca si queremos verla, pero como el UI pide mostrar los zero también
        // los vamos a agregar todos para renderizar el tab, y la UI se encargará de si lo esconde o no,
        // o podemos simplemente devolver todo. Devolveremos todo.
        result.add(
          FincaConLotesAccion(
            finca: finca,
            lotesDisponibles: disponibles,
            ciclosPorLote: ciclosAsociados,
          ),
        );
      }

      return AsyncValue.data(result);
    });
