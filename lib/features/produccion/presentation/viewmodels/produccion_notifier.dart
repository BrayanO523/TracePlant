import 'dart:async';
import 'package:state_notifier/state_notifier.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';
import '../../domain/repositories/produccion_repository.dart';

/// State del módulo de producción (ciclos activos + historial)
class ProduccionState {
  final List<CicloProduccion> ciclos;
  final CicloProduccion? cicloSeleccionado;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ProduccionState({
    this.ciclos = const [],
    this.cicloSeleccionado,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ProduccionState copyWith({
    List<CicloProduccion>? ciclos,
    CicloProduccion? cicloSeleccionado,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearCicloSeleccionado = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProduccionState(
      ciclos: ciclos ?? this.ciclos,
      cicloSeleccionado: clearCicloSeleccionado
          ? null
          : (cicloSeleccionado ?? this.cicloSeleccionado),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  /// Determina el siguiente paso disponible para un lote dado
  TipoEvento? siguientePaso(String idLote) {
    final cicloActivo = ciclos.where(
      (c) =>
          c.idLote == idLote &&
          (c.estado == EstadoCiclo.abierto ||
              c.estado == EstadoCiclo.encintado),
    );

    if (cicloActivo.isEmpty) return TipoEvento.apertura;

    final ciclo = cicloActivo.first;
    if (ciclo.estado == EstadoCiclo.abierto) return TipoEvento.encintado;
    if (ciclo.estado == EstadoCiclo.encintado) return TipoEvento.cosecha;
    return null;
  }
}

/// Notifier principal de producción.
class ProduccionNotifier extends StateNotifier<ProduccionState> {
  final ProduccionRepository _repository;
  final String productoraId;
  StreamSubscription? _ciclosSubscription;

  ProduccionNotifier(this._repository, this.productoraId)
    : super(const ProduccionState(isLoading: true)) {
    _watchCiclos();
  }

  // ═══════════════════════════════════════════════════════
  //  STREAMS
  // ═══════════════════════════════════════════════════════

  void _watchCiclos() {
    _ciclosSubscription?.cancel();
    _ciclosSubscription = _repository
        .watchCiclos(productoraId)
        .listen(
          (ciclos) {
            state = state.copyWith(
              ciclos: ciclos,
              isLoading: false,
              clearError: true,
            );
          },
          onError: (e) {
            state = state.copyWith(
              isLoading: false,
              error: 'Error al cargar ciclos: $e',
            );
          },
        );
  }

  void seleccionarCiclo(CicloProduccion ciclo) {
    state = state.copyWith(cicloSeleccionado: ciclo);
  }

  // ═══════════════════════════════════════════════════════
  //  APERTURA
  // ═══════════════════════════════════════════════════════

  Future<bool> registrarApertura({
    required String idLote,
    required String nombreLote,
    required double area,
    required String variedad,
    required String uidUsuario,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    if (area <= 0) {
      state = state.copyWith(
        isLoading: false,
        error: 'El área debe ser mayor a 0',
      );
      return false;
    }

    final result = await _repository.registrarApertura(
      idLote: idLote,
      nombreLote: nombreLote,
      area: area,
      variedad: variedad,
      productoraId: productoraId,
      uidUsuario: uidUsuario,
    );

    switch (result) {
      case Success(data: final ciclo):
        state = state.copyWith(
          isLoading: false,
          cicloSeleccionado: ciclo,
          successMessage: 'Apertura registrada exitosamente',
        );
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  //  ENCINTADO
  // ═══════════════════════════════════════════════════════

  Future<bool> registrarEncintado({
    required String idCiclo,
    required ColorCinta colorCinta,
    required double cantidad,
    required String uidUsuario,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    if (cantidad <= 0) {
      state = state.copyWith(
        isLoading: false,
        error: 'La cantidad debe ser mayor a 0',
      );
      return false;
    }

    final result = await _repository.registrarEncintado(
      idCiclo: idCiclo,
      colorCinta: colorCinta,
      cantidad: cantidad,
      productoraId: productoraId,
      uidUsuario: uidUsuario,
    );

    switch (result) {
      case Success(data: final ciclo):
        state = state.copyWith(
          isLoading: false,
          cicloSeleccionado: ciclo,
          successMessage: 'Encintado registrado exitosamente',
        );
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  //  COSECHA
  // ═══════════════════════════════════════════════════════

  Future<bool> registrarCosecha({
    required String idCiclo,
    required double cantidad,
    required String uidUsuario,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    if (cantidad <= 0) {
      state = state.copyWith(
        isLoading: false,
        error: 'La cantidad debe ser mayor a 0',
      );
      return false;
    }

    final result = await _repository.registrarCosecha(
      idCiclo: idCiclo,
      cantidad: cantidad,
      productoraId: productoraId,
      uidUsuario: uidUsuario,
    );

    switch (result) {
      case Success(data: final ciclo):
        state = state.copyWith(
          isLoading: false,
          cicloSeleccionado: ciclo,
          successMessage:
              'Cosecha registrada. Merma: ${ciclo.merma?.toStringAsFixed(2) ?? "N/A"}',
        );
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  @override
  void dispose() {
    _ciclosSubscription?.cancel();
    super.dispose();
  }
}
