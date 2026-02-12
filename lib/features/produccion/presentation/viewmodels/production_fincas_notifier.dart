import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../administracion/domain/entities/finca.dart';
import '../../domain/repositories/produccion_repository.dart';

// State
class ProductionFincasState {
  final List<Finca> fincas;
  final bool isLoading;
  final String? error;

  const ProductionFincasState({
    this.fincas = const [],
    this.isLoading = false,
    this.error,
  });

  ProductionFincasState copyWith({
    List<Finca>? fincas,
    bool? isLoading,
    String? error,
  }) {
    return ProductionFincasState(
      fincas: fincas ?? this.fincas,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier
class ProductionFincasNotifier extends StateNotifier<ProductionFincasState> {
  final ProduccionRepository _repository;
  final String productoraId;
  StreamSubscription? _subscription;

  ProductionFincasNotifier(this._repository, this.productoraId)
    : super(const ProductionFincasState(isLoading: true)) {
    _watchFincas();
  }

  void _watchFincas() {
    _subscription?.cancel();
    _subscription = _repository
        .watchFincas(productoraId)
        .listen(
          (fincas) {
            state = state.copyWith(
              fincas: fincas,
              isLoading: false,
              error: null,
            );
          },
          onError: (e) {
            state = state.copyWith(
              isLoading: false,
              error: 'Error al cargar fincas: $e',
            );
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Provider
final productionFincasProvider = StateNotifierProvider.autoDispose
    .family<ProductionFincasNotifier, ProductionFincasState, String>((
      ref,
      productoraId,
    ) {
      return ProductionFincasNotifier(
        ref.read(produccionRepositoryProvider),
        productoraId,
      );
    });
