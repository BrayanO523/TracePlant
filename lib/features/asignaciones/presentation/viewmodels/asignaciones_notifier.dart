import 'dart:async';
import 'package:state_notifier/state_notifier.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/result.dart';
import '../../../productora/domain/entities/productora.dart';
import '../../../empacadora/domain/entities/empacadora.dart';
import '../../../produccion/domain/entities/lote.dart';
import '../../domain/entities/asignacion.dart';
import '../../domain/repositories/asignaciones_repository.dart';

// ═══════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════

class AsignacionesState extends Equatable {
  final List<Asignacion> asignaciones;
  final List<Productora> productorasDisponibles;
  final List<Empacadora> empacadoras;
  final Map<String, int> cargaTrabajo;
  final Map<String, List<Lote>> lotesPorProductora;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AsignacionesState({
    this.asignaciones = const [],
    this.productorasDisponibles = const [],
    this.empacadoras = const [],
    this.cargaTrabajo = const {},
    this.lotesPorProductora = const {},
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AsignacionesState copyWith({
    List<Asignacion>? asignaciones,
    List<Productora>? productorasDisponibles,
    List<Empacadora>? empacadoras,
    Map<String, int>? cargaTrabajo,
    Map<String, List<Lote>>? lotesPorProductora,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AsignacionesState(
      asignaciones: asignaciones ?? this.asignaciones,
      productorasDisponibles:
          productorasDisponibles ?? this.productorasDisponibles,
      empacadoras: empacadoras ?? this.empacadoras,
      cargaTrabajo: cargaTrabajo ?? this.cargaTrabajo,
      lotesPorProductora: lotesPorProductora ?? this.lotesPorProductora,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Asignaciones activas agrupadas por empacadora (para Mapa de Relaciones).
  Map<Empacadora, List<Asignacion>> get asignacionesPorEmpacadora {
    final map = <String, List<Asignacion>>{};
    for (final a in asignaciones) {
      map.putIfAbsent(a.idEmpacadora, () => []).add(a);
    }
    // Mapear con la empacadora real
    final result = <Empacadora, List<Asignacion>>{};
    for (final emp in empacadoras) {
      result[emp] = map[emp.id] ?? [];
    }
    return result;
  }

  @override
  List<Object?> get props => [
    asignaciones,
    productorasDisponibles,
    empacadoras,
    cargaTrabajo,
    lotesPorProductora,
    isLoading,
    error,
    successMessage,
  ];
}

// ═══════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════

class AsignacionesNotifier extends StateNotifier<AsignacionesState> {
  final AsignacionesRepository _repository;
  StreamSubscription<List<Asignacion>>? _subscription;

  AsignacionesNotifier(this._repository)
    : super(const AsignacionesState(isLoading: true)) {
    _init();
  }

  void _init() {
    // Suscribirse al stream de asignaciones activas
    _subscription = _repository.watchAsignacionesActivas().listen(
      (asignaciones) {
        state = state.copyWith(asignaciones: asignaciones, isLoading: false);
      },
      onError: (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al cargar asignaciones: $e',
        );
      },
    );

    // Cargar datos estáticos (empacadoras, productoras disponibles, carga)
    _loadStaticData();
  }

  /// Carga empacadoras activas, productoras disponibles y carga de trabajo.
  Future<void> _loadStaticData() async {
    try {
      final results = await Future.wait([
        _repository.getEmpacadorasActivas(),
        _repository.getProductorasDisponibles(),
        _repository.getCargaTrabajo(),
      ]);

      final productoras = results[1] as List<Productora>;

      // Cargar lotes de estas productoras
      // Esto podría hacerse en paralelo con lo anterior si tuvieramos los IDs antes,
      // pero requerimos la lista primeros.
      Map<String, List<Lote>> lotes = {};
      if (productoras.isNotEmpty) {
        lotes = await _repository.getLotesDeProductoras(
          productoras.map((p) => p.id).toList(),
        );
      }

      state = state.copyWith(
        empacadoras: results[0] as List<Empacadora>,
        productorasDisponibles: productoras,
        cargaTrabajo: results[2] as Map<String, int>,
        lotesPorProductora: lotes,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar datos: $e');
    }
  }

  /// Recarga todos los datos (empacadoras, productoras, carga).
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadStaticData();
    state = state.copyWith(isLoading: false);
  }

  /// Asigna múltiples productoras a una empacadora.
  Future<void> asignarBatch({
    required String idEmpacadora,
    required List<String> idsProductoras,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.crearAsignacionesBatch(
      idEmpacadora: idEmpacadora,
      idsProductoras: idsProductoras,
    );

    switch (result) {
      case Success():
        // Recargar datos para reflejar cambios
        await _loadStaticData();
        state = state.copyWith(
          isLoading: false,
          successMessage: '${idsProductoras.length} productora(s) asignada(s)',
        );
      case FailureResult(:final failure):
        state = state.copyWith(isLoading: false, error: failure.message);
    }
  }

  /// Desasigna (finaliza) una asignación, liberando la productora.
  Future<void> desasignar(String idAsignacion) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.finalizarAsignacion(idAsignacion);

    switch (result) {
      case Success():
        await _loadStaticData();
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Productora desasignada correctamente',
        );
      case FailureResult(:final failure):
        state = state.copyWith(isLoading: false, error: failure.message);
    }
  }

  /// Limpia mensajes de error/éxito.
  void clearMessages() {
    state = state.copyWith();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
