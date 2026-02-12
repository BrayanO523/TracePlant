import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../../produccion/domain/entities/ciclo_produccion.dart';
import '../../../produccion/domain/entities/produccion_enums.dart'; // Restore import

import '../../../productora/domain/entities/productora.dart';
import '../../domain/repositories/empacadora_repository.dart';

// ═══════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════

class EmpacadoraDashboardState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Productora> productorasAsignadas;
  final List<CicloProduccion> ciclosActivos;

  // Métricas agregadas
  final double totalHectareasActivas;
  final double totalKilosProyectados; // Basado en encintado
  final Map<String, double> proyeccionPorColor; // Kilos por nombre de cinta
  final Map<String, int> cantidadCiclosPorColor;

  const EmpacadoraDashboardState({
    this.isLoading = true,
    this.error,
    this.productorasAsignadas = const [],
    this.ciclosActivos = const [],
    this.totalHectareasActivas = 0,
    this.totalKilosProyectados = 0,
    this.proyeccionPorColor = const {},
    this.cantidadCiclosPorColor = const {},
  });

  EmpacadoraDashboardState copyWith({
    bool? isLoading,
    String? error,
    List<Productora>? productorasAsignadas,
    List<CicloProduccion>? ciclosActivos,
    double? totalHectareasActivas,
    double? totalKilosProyectados,
    Map<String, double>? proyeccionPorColor,
    Map<String, int>? cantidadCiclosPorColor,
  }) {
    return EmpacadoraDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      productorasAsignadas: productorasAsignadas ?? this.productorasAsignadas,
      ciclosActivos: ciclosActivos ?? this.ciclosActivos,
      totalHectareasActivas:
          totalHectareasActivas ?? this.totalHectareasActivas,
      totalKilosProyectados:
          totalKilosProyectados ?? this.totalKilosProyectados,
      proyeccionPorColor: proyeccionPorColor ?? this.proyeccionPorColor,
      cantidadCiclosPorColor:
          cantidadCiclosPorColor ?? this.cantidadCiclosPorColor,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    productorasAsignadas,
    ciclosActivos,
    totalHectareasActivas,
    totalKilosProyectados,
    proyeccionPorColor,
    cantidadCiclosPorColor,
  ];
}

// ═══════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════

class EmpacadoraDashboardNotifier
    extends StateNotifier<EmpacadoraDashboardState> {
  final EmpacadoraRepository _repository;
  final String _empacadoraId;
  StreamSubscription<List<CicloProduccion>>? _ciclosSubscription;

  EmpacadoraDashboardNotifier(this._repository, this._empacadoraId)
    : super(const EmpacadoraDashboardState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Obtener productoras asignadas
      final productoras = await _repository.getProductorasAsignadas(
        _empacadoraId,
      );

      state = state.copyWith(productorasAsignadas: productoras);

      if (productoras.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // 2. Suscribirse a los ciclos de esas productoras
      final ids = productoras.map((p) => p.id).toList();
      _ciclosSubscription = _repository
          .watchCiclosDeProductoras(ids)
          .listen(
            (ciclos) {
              _procesarCiclos(ciclos);
            },
            onError: (e) {
              state = state.copyWith(
                error: 'Error cargando producción: $e',
                isLoading: false,
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        error: 'Error inicializando dashboard: $e',
        isLoading: false,
      );
    }
  }

  void _procesarCiclos(List<CicloProduccion> ciclos) {
    double totalAreas = 0;
    double totalKilos = 0;
    final Map<String, double> porColor = {};
    final Map<String, int> countPorColor = {};

    for (var ciclo in ciclos) {
      // Filtrar solo ciclos relevantes (sembrados o encintados)
      if (ciclo.estado == EstadoCiclo.cosechado ||
          ciclo.estado == EstadoCiclo.cancelado) {
        continue;
      }

      // Sumar Hectáreas
      totalAreas += ciclo.area;

      // Proyección basada en encintados
      for (var encintado in ciclo.encintados) {
        // Asumimos encintado.cantidad es el volumen estimado bruto
        totalKilos += encintado.cantidad;

        porColor.update(
          encintado.cintaNombre,
          (val) => val + encintado.cantidad,
          ifAbsent: () => encintado.cantidad,
        );

        countPorColor.update(
          encintado.cintaNombre,
          (val) => val + 1,
          ifAbsent: () => 1,
        );
      }
    }

    state = state.copyWith(
      isLoading: false,
      ciclosActivos: ciclos,
      totalHectareasActivas: totalAreas,
      totalKilosProyectados: totalKilos,
      proyeccionPorColor: porColor,
      cantidadCiclosPorColor: countPorColor,
    );
  }

  @override
  void dispose() {
    _ciclosSubscription?.cancel();
    super.dispose();
  }
}
