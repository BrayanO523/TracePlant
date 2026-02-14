import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../../produccion/domain/entities/ciclo_produccion.dart';
import '../../../produccion/domain/entities/produccion_enums.dart';

import '../../../productora/domain/entities/productora.dart';
import '../../domain/repositories/empacadora_repository.dart';

// ═══════════════════════════════════════════════════════
//  Modelo auxiliar para proyección por color de cinta
// ═══════════════════════════════════════════════════════

class ProyeccionCinta {
  final String nombre;
  final String colorHex;
  final double cantidad;
  final int ciclos;
  final String nombreLote;
  final String nombreFinca;
  final String nombreProductora;
  final CicloProduccion ciclo;

  const ProyeccionCinta({
    required this.nombre,
    required this.colorHex,
    required this.cantidad,
    required this.ciclos,
    required this.ciclo,
    this.nombreLote = '',
    this.nombreFinca = '',
    this.nombreProductora = '',
  });
}

// ═══════════════════════════════════════════════════════
//  Modelo auxiliar para próxima cosecha
// ═══════════════════════════════════════════════════════

class ProximaCosecha {
  final CicloProduccion ciclo;
  final DateTime fechaProyectada;
  final int diasRestantes;
  final String productoraName;
  final String nombreLote;
  final String nombreFinca;

  const ProximaCosecha({
    required this.ciclo,
    required this.fechaProyectada,
    required this.diasRestantes,
    required this.productoraName,
    this.nombreLote = '',
    this.nombreFinca = '',
  });
}

// ═══════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════

class EmpacadoraDashboardState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Productora> productorasAsignadas;
  final List<CicloProduccion> ciclosActivos;

  // Métricas agregadas
  final double totalKilosProyectados; // Basado en encintado
  final int totalCiclosActivos;
  final Map<String, double> proyeccionPorColor;
  final Map<String, int> cantidadCiclosPorColor;

  // Datos enriquecidos
  final List<ProyeccionCinta> proyeccionesCinta;
  final List<ProximaCosecha> proximasCosechas;
  final Map<String, int> ciclosPorProductora; // id_productora -> count

  const EmpacadoraDashboardState({
    this.isLoading = true,
    this.error,
    this.productorasAsignadas = const [],
    this.ciclosActivos = const [],
    this.totalKilosProyectados = 0,
    this.totalCiclosActivos = 0,
    this.proyeccionPorColor = const {},
    this.cantidadCiclosPorColor = const {},
    this.proyeccionesCinta = const [],
    this.proximasCosechas = const [],
    this.ciclosPorProductora = const {},
  });

  EmpacadoraDashboardState copyWith({
    bool? isLoading,
    String? error,
    List<Productora>? productorasAsignadas,
    List<CicloProduccion>? ciclosActivos,
    double? totalKilosProyectados,
    int? totalCiclosActivos,
    Map<String, double>? proyeccionPorColor,
    Map<String, int>? cantidadCiclosPorColor,
    List<ProyeccionCinta>? proyeccionesCinta,
    List<ProximaCosecha>? proximasCosechas,
    Map<String, int>? ciclosPorProductora,
  }) {
    return EmpacadoraDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      productorasAsignadas: productorasAsignadas ?? this.productorasAsignadas,
      ciclosActivos: ciclosActivos ?? this.ciclosActivos,
      totalKilosProyectados:
          totalKilosProyectados ?? this.totalKilosProyectados,
      totalCiclosActivos: totalCiclosActivos ?? this.totalCiclosActivos,
      proyeccionPorColor: proyeccionPorColor ?? this.proyeccionPorColor,
      cantidadCiclosPorColor:
          cantidadCiclosPorColor ?? this.cantidadCiclosPorColor,
      proyeccionesCinta: proyeccionesCinta ?? this.proyeccionesCinta,
      proximasCosechas: proximasCosechas ?? this.proximasCosechas,
      ciclosPorProductora: ciclosPorProductora ?? this.ciclosPorProductora,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    productorasAsignadas,
    ciclosActivos,
    totalKilosProyectados,
    totalCiclosActivos,
    proyeccionPorColor,
    cantidadCiclosPorColor,
    proyeccionesCinta,
    proximasCosechas,
    ciclosPorProductora,
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

  /// Mapa loteId → nombreFinca (cargado al inicio)
  Map<String, String> _loteFincaMap = {};

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

      final ids = productoras.map((p) => p.id).toList();

      // 2. Cargar mapa loteId → nombreFinca
      _loteFincaMap = await _repository.fetchLoteFincaMap(ids);

      // 3. Suscribirse a los ciclos de esas productoras
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
    double totalKilos = 0;
    int totalActivos = 0;
    final Map<String, double> porColor = {};
    final Map<String, int> countPorColor = {};
    final Map<String, String> hexPorColor = {};
    final Map<String, int> ciclosPorProd = {};
    final now = DateTime.now();
    final List<ProximaCosecha> cosechas = [];

    // Mapa nombre productora por id
    final prodNames = <String, String>{};
    for (var p in state.productorasAsignadas) {
      prodNames[p.id] = p.name;
    }

    // Lista de proyecciones individuales por encintado
    final List<ProyeccionCinta> proyeccionesDetalle = [];

    for (var ciclo in ciclos) {
      // Filtrar solo ciclos relevantes (sembrados o encintados)
      if (ciclo.estado == EstadoCiclo.cosechado ||
          ciclo.estado == EstadoCiclo.cancelado) {
        continue;
      }

      totalActivos++;

      // Ciclos por productora
      ciclosPorProd.update(ciclo.idProductora, (v) => v + 1, ifAbsent: () => 1);

      final nombreFinca = _loteFincaMap[ciclo.idLote] ?? '';
      final nombreProd = prodNames[ciclo.idProductora] ?? 'Productora';

      // Proyección basada en encintados
      for (var encintado in ciclo.encintados) {
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

        // Guardar hex del color
        if (!hexPorColor.containsKey(encintado.cintaNombre)) {
          hexPorColor[encintado.cintaNombre] = encintado.cintaColorHex;
        }

        // Proyección individual
        proyeccionesDetalle.add(
          ProyeccionCinta(
            nombre: encintado.cintaNombre,
            colorHex: encintado.cintaColorHex,
            cantidad: encintado.cantidad,
            ciclos: 1,
            ciclo: ciclo,
            nombreLote: ciclo.nombreLote,
            nombreFinca: nombreFinca,
            nombreProductora: nombreProd,
          ),
        );
      }

      // Próximas cosechas (solo encintados con proyección)
      if (ciclo.estado == EstadoCiclo.encintado) {
        // Usar semanas default por productora
        final semanasDefault = _getSemanasForProductora(ciclo.idProductora);
        final proy = ciclo.proyeccionCosecha(semanasDefault);
        if (proy != null) {
          cosechas.add(
            ProximaCosecha(
              ciclo: ciclo,
              fechaProyectada: proy,
              diasRestantes: proy.difference(now).inDays,
              productoraName: nombreProd,
              nombreLote: ciclo.nombreLote,
              nombreFinca: nombreFinca,
            ),
          );
        }
      }
    }

    // Ordenar cosechas por díasRestantes asc (más próxima primero)
    cosechas.sort((a, b) => a.diasRestantes.compareTo(b.diasRestantes));

    // Ordenar proyecciones por cantidad desc
    proyeccionesDetalle.sort((a, b) => b.cantidad.compareTo(a.cantidad));

    state = state.copyWith(
      isLoading: false,
      ciclosActivos: ciclos,
      totalKilosProyectados: totalKilos,
      totalCiclosActivos: totalActivos,
      proyeccionPorColor: porColor,
      cantidadCiclosPorColor: countPorColor,
      proyeccionesCinta: proyeccionesDetalle,
      proximasCosechas: cosechas.take(8).toList(),
      ciclosPorProductora: ciclosPorProd,
    );
  }

  int _getSemanasForProductora(String productoraId) {
    try {
      final p = state.productorasAsignadas.firstWhere(
        (p) => p.id == productoraId,
      );
      return p.semanasParaCosecha;
    } catch (_) {
      return 30; // Default
    }
  }

  @override
  void dispose() {
    _ciclosSubscription?.cancel();
    super.dispose();
  }
}
