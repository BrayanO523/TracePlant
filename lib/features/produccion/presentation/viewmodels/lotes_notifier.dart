import 'dart:async';
import 'package:state_notifier/state_notifier.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/lote.dart';
import '../../domain/repositories/produccion_repository.dart';

/// State para la gestión de lotes
class LotesState {
  final List<Lote> lotes;
  final bool isLoading;
  final String? error;

  const LotesState({this.lotes = const [], this.isLoading = false, this.error});

  LotesState copyWith({
    List<Lote>? lotes,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LotesState(
      lotes: lotes ?? this.lotes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier que gestiona la lista de lotes de una productora.
class LotesNotifier extends StateNotifier<LotesState> {
  final ProduccionRepository _repository;
  final String productoraId;
  StreamSubscription? _subscription;

  LotesNotifier(this._repository, this.productoraId)
    : super(const LotesState(isLoading: true)) {
    _watchLotes();
  }

  void _watchLotes() {
    _subscription?.cancel();
    _subscription = _repository
        .watchLotes(productoraId)
        .listen(
          (lotes) {
            state = state.copyWith(
              lotes: lotes,
              isLoading: false,
              clearError: true,
            );
          },
          onError: (e) {
            state = state.copyWith(
              isLoading: false,
              error: 'Error al cargar lotes: $e',
            );
          },
        );
  }

  Future<void> crearLote({
    required String nombre,
    required double area,
    required String variedad,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.crearLote(
      nombre: nombre,
      area: area,
      variedad: variedad,
      productoraId: productoraId,
    );

    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false);
      case FailureResult(failure: final f):
        state = state.copyWith(isLoading: false, error: f.message);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
