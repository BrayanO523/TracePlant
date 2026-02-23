import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/ciclo_produccion.dart';
import '../../../domain/entities/produccion_enums.dart';
import '../../../../../app/di/providers.dart';
import '../../../domain/logic/encintado_cohortes_logic.dart'; // Import nuevo

import '../../../../administracion/domain/entities/finca.dart';
import '../../../../administracion/domain/entities/cinta.dart'; // Nuevo
import '../../../../administracion/domain/entities/variedad.dart'; // Nuevo
import '../../../domain/entities/lote.dart';

// ── Modelo local para proyección ──
class ProximaCosechaLocal {
  final CicloProduccion ciclo;
  final DateTime fechaProyectada;
  final int diasRestantes;

  const ProximaCosechaLocal({
    required this.ciclo,
    required this.fechaProyectada,
    required this.diasRestantes,
  });
}

class ConsultasState {
  final bool isLoading;
  final String? error;

  // Datos completos
  final List<CicloProduccion> ciclos;
  final List<Finca> fincas;
  final List<Lote> lotes;
  final List<Cinta> cintas; // Nuevo: Master Data
  final List<Variedad> variedades; // Nuevo: Master Data

  // Datos filtrados para mostrar
  final List<CicloProduccion> ciclosFiltrados;

  // Filtros activos
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? cintaFilter; // Hex color filter
  final String? variedadFilter; // Variedad Name filter
  final String? loteFilter; // Lote ID filter
  final String? fincaFilter; // Nuevo: Finca Name filter
  final bool sortAscending; // Nuevo: Ordenamiento

  // Totales calculados (basados en filtros)
  final double totalEncintado;
  final double totalCosechado;
  final int totalCiclos;

  // Cosecha Pendiente: ciclos encintados pendientes de cosecha
  final List<CicloProduccion> cosechasPendientes;
  final double totalCosechasPendientes;

  // Proyecciones de cosecha (Old & New)
  final int semanasParaCosecha;
  final List<ProximaCosechaLocal>
  proximasCosechas; // Deprecated? Mantener por ahora
  final List<CohorteResumen> cohortes; // Nueva Lógica Agrupada

  const ConsultasState({
    this.isLoading = false,
    this.error,
    this.ciclos = const [],
    this.fincas = const [],
    this.lotes = const [],
    this.cintas = const [],
    this.variedades = const [],
    this.ciclosFiltrados = const [],
    this.fechaInicio,
    this.fechaFin,
    this.cintaFilter,
    this.variedadFilter,
    this.loteFilter,
    this.fincaFilter,
    this.sortAscending = false, // Default: Descendente (más reciente primero)
    this.totalEncintado = 0,
    this.totalCosechado = 0,
    this.totalCiclos = 0,
    this.cosechasPendientes = const [],
    this.totalCosechasPendientes = 0,
    this.semanasParaCosecha = 30,
    this.proximasCosechas = const [],
    this.cohortes = const [],
  });

  ConsultasState copyWith({
    bool? isLoading,
    String? error,
    List<CicloProduccion>? ciclos,
    List<Finca>? fincas,
    List<Lote>? lotes,
    List<Cinta>? cintas,
    List<Variedad>? variedades,
    List<CicloProduccion>? ciclosFiltrados,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? cintaFilter,
    String? variedadFilter,
    String? loteFilter,
    String? fincaFilter,
    bool? sortAscending,
    double? totalEncintado,
    double? totalCosechado,
    int? totalCiclos,
    List<CicloProduccion>? cosechasPendientes,
    double? totalCosechasPendientes,
    int? semanasParaCosecha,
    List<ProximaCosechaLocal>? proximasCosechas,
    List<CohorteResumen>? cohortes,
  }) {
    return ConsultasState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ciclos: ciclos ?? this.ciclos,
      fincas: fincas ?? this.fincas,
      lotes: lotes ?? this.lotes,
      cintas: cintas ?? this.cintas,
      variedades: variedades ?? this.variedades,
      ciclosFiltrados: ciclosFiltrados ?? this.ciclosFiltrados,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      cintaFilter: cintaFilter ?? this.cintaFilter,
      variedadFilter: variedadFilter ?? this.variedadFilter,
      loteFilter: loteFilter ?? this.loteFilter,
      fincaFilter: fincaFilter ?? this.fincaFilter,
      sortAscending: sortAscending ?? this.sortAscending,
      totalEncintado: totalEncintado ?? this.totalEncintado,
      totalCosechado: totalCosechado ?? this.totalCosechado,
      totalCiclos: totalCiclos ?? this.totalCiclos,
      cosechasPendientes: cosechasPendientes ?? this.cosechasPendientes,
      totalCosechasPendientes:
          totalCosechasPendientes ?? this.totalCosechasPendientes,
      semanasParaCosecha: semanasParaCosecha ?? this.semanasParaCosecha,
      proximasCosechas: proximasCosechas ?? this.proximasCosechas,
      cohortes: cohortes ?? this.cohortes,
    );
  }
}

class ConsultasNotifier extends StateNotifier<ConsultasState> {
  final Ref ref;
  final String productoraId;

  ConsultasNotifier(this.ref, this.productoraId)
    : super(const ConsultasState()) {
    _loadSemanasParaCosecha();
    _subscribeToCiclos();
    _subscribeToDatosMaestros(); // Nuevo: Fincas y Lotes
  }

  /// Lee semanasParaCosecha de la productora en Firestore
  Future<void> _loadSemanasParaCosecha() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('productoras')
          .doc(productoraId)
          .get();
      if (doc.exists && mounted) {
        final raw = doc.data()?['semanas_para_cosecha'];
        final semanas = (raw as num?)?.toInt() ?? 30;
        state = state.copyWith(semanasParaCosecha: semanas);
        // Recalcular proyecciones con el valor real
        _calculateProyecciones();
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> refresh() async {
    // Recargar configuraciones
    await _loadSemanasParaCosecha();
    // Simular un pequeño delay para feedback visual
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _subscribeToDatosMaestros() {
    final repo = ref.read(produccionRepositoryProvider);
    // Fincas
    repo.watchFincas(productoraId).listen((fincas) {
      if (mounted) state = state.copyWith(fincas: fincas);
    });
    // Lotes
    repo.watchLotes(productoraId).listen((lotes) {
      if (mounted) state = state.copyWith(lotes: lotes);
    });

    // Nuevo: Master Data de Cintas y Variedades
    final adminRepo = ref.read(administracionRepositoryProvider);

    adminRepo.watchCintas(productoraId: productoraId).listen((cintas) {
      if (mounted) state = state.copyWith(cintas: cintas);
    });

    adminRepo.watchVariedades(productoraId: productoraId).listen((variedades) {
      if (mounted) state = state.copyWith(variedades: variedades);
    });
  }

  void _subscribeToCiclos() {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(produccionRepositoryProvider);

    // Suscribirse al stream de ciclos ACTIVOS (escalabilidad)
    repo
        .watchCiclosActivos(productoraId)
        .listen(
          (ciclos) {
            if (mounted) {
              // Al recibir nuevos datos, actualizamos la lista maestra y reaplicamos filtros
              state = state.copyWith(isLoading: false, ciclos: ciclos);
              _applyFilters();
              _calculateCosechasPendientes();
            }
          },
          onError: (err) {
            if (mounted) {
              state = state.copyWith(isLoading: false, error: err.toString());
            }
          },
        );
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(fechaInicio: start, fechaFin: end);
    // Aplicar filtros recalcula todo
    _applyFilters();
  }

  void setFilters({
    String? cintaFilter,
    String? variedadFilter,
    String? loteFilter,
    String? fincaFilter,
    bool? sortAscending,
    DateTime? startDate,
    DateTime? endDate,
    bool resetOthers = false,
  }) {
    if (resetOthers) {
      // Reconstruir estado conservando solo DATA, reseteando filtros
      state = ConsultasState(
        isLoading: state.isLoading,
        error: state.error,
        ciclos: state.ciclos,
        fincas: state.fincas,
        lotes: state.lotes,
        cintas: state.cintas, // FIX: Preservar Master Data
        variedades: state.variedades, // FIX: Preservar Master Data
        // Filtros nuevos (nulos si no se pasan)
        cintaFilter: cintaFilter,
        variedadFilter: variedadFilter,
        loteFilter: loteFilter,
        fincaFilter: fincaFilter,
        fechaInicio: startDate,
        fechaFin: endDate,
        sortAscending: sortAscending ?? false,
        // Mantener calculados (se recalcularán en _applyFilters)
        cosechasPendientes: state.cosechasPendientes,
        totalCosechasPendientes: state.totalCosechasPendientes,
        semanasParaCosecha: state.semanasParaCosecha,
        cohortes: state.cohortes,
        proximasCosechas: state.proximasCosechas,
      );
    } else {
      // Merge normal
      state = state.copyWith(
        cintaFilter: cintaFilter,
        variedadFilter: variedadFilter,
        loteFilter: loteFilter,
        fincaFilter: fincaFilter,
        sortAscending: sortAscending,
        fechaInicio: startDate,
        fechaFin: endDate,
      );
    }
    _applyFilters();
  }

  void replaceFilters({
    bool sortAscending = false,
    DateTime? startDate,
    DateTime? endDate,
    String? cintaFilter,
    String? variedadFilter,
    String? loteFilter,
    String? fincaFilter,
  }) {
    state = ConsultasState(
      isLoading: state.isLoading,
      error: state.error,
      ciclos: state.ciclos,
      fincas: state.fincas,
      lotes: state.lotes,
      cintas: state.cintas,
      variedades: state.variedades,
      ciclosFiltrados: state.ciclosFiltrados,
      totalEncintado: state.totalEncintado,
      totalCosechado: state.totalCosechado,
      totalCiclos: state.totalCiclos,
      cosechasPendientes: state.cosechasPendientes,
      totalCosechasPendientes: state.totalCosechasPendientes,
      semanasParaCosecha: state.semanasParaCosecha,
      proximasCosechas: state.proximasCosechas,
      cohortes: state.cohortes,

      // Exact nullable overrides
      sortAscending: sortAscending,
      fechaInicio: startDate,
      fechaFin: endDate,
      cintaFilter: cintaFilter,
      variedadFilter: variedadFilter,
      loteFilter: loteFilter,
      fincaFilter: fincaFilter,
    );
    _applyFilters();
  }

  void clearFilters() {
    state = ConsultasState(
      isLoading: state.isLoading,
      ciclos: state.ciclos,
      fincas: state.fincas,
      lotes: state.lotes,
      cintas: state.cintas, // FIX: Preservar Master Data
      variedades: state.variedades, // FIX: Preservar Master Data
      ciclosFiltrados: state.ciclos,
      fechaInicio: null,
      fechaFin: null,
      cintaFilter: null,
      variedadFilter: null,
      loteFilter: null,
      fincaFilter: null,
      sortAscending: false,
      totalEncintado: state.totalEncintado,
      totalCosechado: state.totalCosechado,
      totalCiclos: state.totalCiclos,
      semanasParaCosecha: state.semanasParaCosecha,
      proximasCosechas: state.proximasCosechas,
      cosechasPendientes: state.cosechasPendientes,
      totalCosechasPendientes: state.totalCosechasPendientes,
      cohortes: state.cohortes,
    );
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = state.ciclos;

    // 1. Filtro de Fecha
    if (state.fechaInicio != null && state.fechaFin != null) {
      filtered = filtered.where((c) {
        return c.fechaSiembra.isAfter(
              state.fechaInicio!.subtract(const Duration(days: 1)),
            ) &&
            c.fechaSiembra.isBefore(
              state.fechaFin!.add(const Duration(days: 1)),
            );
      }).toList();
    }

    // 2. Filtro de Variedad
    if (state.variedadFilter != null && state.variedadFilter!.isNotEmpty) {
      filtered = filtered
          .where((c) => c.variedad == state.variedadFilter)
          .toList();
    }

    // 3. Filtro de Color de Cinta
    if (state.cintaFilter != null) {
      filtered = filtered.where((c) {
        return c.encintados.any((e) => e.cintaColorHex == state.cintaFilter);
      }).toList();
    }

    // 4. Filtro de Lote (POR ID)
    if (state.loteFilter != null && state.loteFilter!.isNotEmpty) {
      filtered = filtered.where((c) => c.idLote == state.loteFilter).toList();
    }

    // 4.5. Filtro de Finca (Por Nombre)
    if (state.fincaFilter != null && state.fincaFilter!.isNotEmpty) {
      // Resolver ID de finca
      final matches = state.fincas.where((f) => f.nombre == state.fincaFilter);
      if (matches.isNotEmpty) {
        final fincaId = matches.first.id;
        // Buscar lotes de esa finca
        final lotesIds = state.lotes
            .where((l) => l.fincaId == fincaId)
            .map((l) => l.id)
            .toSet();
        filtered = filtered.where((c) => lotesIds.contains(c.idLote)).toList();
      } else {
        filtered = [];
      }
    }

    // 5. Ordenamiento
    filtered.sort((a, b) {
      final dateA = a.fechaSiembra;
      final dateB = b.fechaSiembra;
      return state.sortAscending
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    _calculateTotals(filtered);
    // Recalcular proyecciones con los datos filtrados
    _calculateProyecciones();
  }

  void _calculateTotals(List<CicloProduccion> filteredList) {
    double encintado = 0;
    double cosechado = 0;

    final colorFilter = state.cintaFilter;

    for (var ciclo in filteredList) {
      // Sumar encintados
      if (ciclo.encintados.isNotEmpty) {
        for (var e in ciclo.encintados) {
          if (colorFilter == null || e.cintaColorHex == colorFilter) {
            encintado += e.cantidad;
          }
        }
      }

      // Sumar cosecha
      if (ciclo.cantidadCosecha != null) {
        cosechado += ciclo.cantidadCosecha!;
      }
    }

    state = state.copyWith(
      ciclosFiltrados: filteredList,
      totalEncintado: encintado,
      totalCosechado: cosechado,
      totalCiclos: filteredList.length,
    );
  }

  /// Calcula lotes cosechados
  void _calculateCosechasPendientes() {
    final inv = state.ciclos
        .where((c) => c.estado == EstadoCiclo.cosechado)
        .toList();
    inv.sort((a, b) {
      final fa = a.fechaCosecha ?? DateTime(2000);
      final fb = b.fechaCosecha ?? DateTime(2000);
      return fb.compareTo(fa); // Más reciente primero
    });
    final total = inv.fold<double>(
      0,
      (acumulador, c) => acumulador + (c.cantidadCosecha ?? 0),
    );
    state = state.copyWith(
      cosechasPendientes: inv,
      totalCosechasPendientes: total,
    );
  }

  /// Calcula proyecciones de cosecha agrupadas por cohortes semanales (Logica Nueva)
  void _calculateProyecciones() {
    final processor =
        EncintadoProcessor(); // Importado de encintado_cohortes_logic.dart
    final List<EncintadoInput> inputs = [];

    // 1. Aplanar todos los encintados de los ciclos FILTRADOS
    // Solo consideramos ciclos NO COSECHADOS FULL (o sea, estado != cosechado)
    final ciclosActivos = state.ciclosFiltrados.where(
      (c) => c.estado != EstadoCiclo.cosechado,
    );

    for (var ciclo in ciclosActivos) {
      for (var e in ciclo.encintados) {
        inputs.add(
          EncintadoInput(
            id: e.id,
            loteId: ciclo.idLote,
            cintaColor: e.cintaNombre,
            cintaColorHex: e.cintaColorHex,
            cantidad: e.cantidad.toInt(),
            fecha: e.fecha,
          ),
        );
      }
    }

    // 2. Procesar con la lógica de negocio (Semanas configurables)
    final cohortesCalculadas = processor.procesarCohortes(
      inputs,
      state.semanasParaCosecha,
    );

    // 3. Mantener lógica vieja (ProximaCosechaLocal) por compatibilidad temporal
    final now = DateTime.now();
    final List<ProximaCosechaLocal> proyeccionesViejas = [];

    for (var ciclo
        in state.cosechasPendientes.isEmpty
            ? state.ciclosFiltrados.where(
                (c) => c.estado == EstadoCiclo.encintado,
              )
            : state.cosechasPendientes) {
      final fecha = ciclo.proyeccionCosecha(state.semanasParaCosecha);
      if (fecha != null) {
        final today = DateTime(now.year, now.month, now.day);
        final projectedDate = DateTime(fecha.year, fecha.month, fecha.day);
        proyeccionesViejas.add(
          ProximaCosechaLocal(
            ciclo: ciclo,
            fechaProyectada: fecha,
            diasRestantes: projectedDate.difference(today).inDays,
          ),
        );
      }
    }
    proyeccionesViejas.sort(
      (a, b) => a.fechaProyectada.compareTo(b.fechaProyectada),
    );

    // Actualizar estado completo
    state = state.copyWith(
      proximasCosechas: proyeccionesViejas,
      cohortes: cohortesCalculadas,
    );
  }

  // --- Aggregation Logic for Charts ---

  Map<String, double> getStatsPorColor() {
    final Map<String, double> distribution = {};
    for (var ciclo in state.ciclosFiltrados) {
      for (var e in ciclo.encintados) {
        final color = e.cintaColorHex;
        distribution[color] = (distribution[color] ?? 0) + e.cantidad;
      }
    }
    return distribution;
  }

  Map<String, double> getProduccionSemanal() {
    final Map<String, double> weeklyProd = {};
    final harvestCycles = state.ciclosFiltrados.where(
      (c) => c.cantidadCosecha != null && c.cantidadCosecha! > 0,
    );

    for (var ciclo in harvestCycles) {
      final date = ciclo.fechaSiembra;
      final week = ((date.dayOfYear - 1) / 7).floor() + 1;
      final key = '$week-${date.year}';
      weeklyProd[key] = (weeklyProd[key] ?? 0) + ciclo.cantidadCosecha!;
    }
    return weeklyProd;
  }
}

extension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}

final consultasProvider =
    StateNotifierProvider.family<ConsultasNotifier, ConsultasState, String>((
      ref,
      productoraId,
    ) {
      return ConsultasNotifier(ref, productoraId);
    });
