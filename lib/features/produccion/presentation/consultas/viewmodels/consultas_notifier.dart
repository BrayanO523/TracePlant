import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/ciclo_produccion.dart';
import '../../../domain/entities/produccion_enums.dart';
import '../../../../../app/di/providers.dart';

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

  // Datos filtrados para mostrar
  final List<CicloProduccion> ciclosFiltrados;

  // Filtros activos
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? cintaFilter; // Hex color filter
  final String? variedadFilter; // Variedad Name filter
  final String? loteFilter; // Lote ID filter

  // Totales calculados (basados en filtros)
  final double totalEncintado;
  final double totalCosechado;
  final int totalCiclos;

  // Inventario: ciclos encintados pendientes de cosecha
  final List<CicloProduccion> inventario;
  final double totalInventario;

  // Proyecciones de cosecha
  final int semanasParaCosecha;
  final List<ProximaCosechaLocal> proximasCosechas;

  const ConsultasState({
    this.isLoading = false,
    this.error,
    this.ciclos = const [],
    this.ciclosFiltrados = const [],
    this.fechaInicio,
    this.fechaFin,
    this.cintaFilter,
    this.variedadFilter,
    this.loteFilter,
    this.totalEncintado = 0,
    this.totalCosechado = 0,
    this.totalCiclos = 0,
    this.inventario = const [],
    this.totalInventario = 0,
    this.semanasParaCosecha = 30,
    this.proximasCosechas = const [],
  });

  ConsultasState copyWith({
    bool? isLoading,
    String? error,
    List<CicloProduccion>? ciclos,
    List<CicloProduccion>? ciclosFiltrados,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? cintaFilter,
    String? variedadFilter,
    String? loteFilter,
    double? totalEncintado,
    double? totalCosechado,
    int? totalCiclos,
    List<CicloProduccion>? inventario,
    double? totalInventario,
    int? semanasParaCosecha,
    List<ProximaCosechaLocal>? proximasCosechas,
  }) {
    return ConsultasState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ciclos: ciclos ?? this.ciclos,
      ciclosFiltrados: ciclosFiltrados ?? this.ciclosFiltrados,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      cintaFilter: cintaFilter ?? this.cintaFilter,
      variedadFilter: variedadFilter ?? this.variedadFilter,
      loteFilter: loteFilter ?? this.loteFilter,
      totalEncintado: totalEncintado ?? this.totalEncintado,
      totalCosechado: totalCosechado ?? this.totalCosechado,
      totalCiclos: totalCiclos ?? this.totalCiclos,
      inventario: inventario ?? this.inventario,
      totalInventario: totalInventario ?? this.totalInventario,
      semanasParaCosecha: semanasParaCosecha ?? this.semanasParaCosecha,
      proximasCosechas: proximasCosechas ?? this.proximasCosechas,
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
        debugPrint('[Consultas] semanas_para_cosecha leído: $raw → $semanas');
        state = state.copyWith(semanasParaCosecha: semanas);
        // Recalcular proyecciones con el valor real
        _calculateProyecciones();
      }
    } catch (e) {
      debugPrint('[Consultas] Error leyendo semanas_para_cosecha: $e');
    }
  }

  void _subscribeToCiclos() {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(produccionRepositoryProvider);

    // Suscribirse al stream de ciclos ACTIVOS (escalabilidad)
    // TODO: Para reportes históricos masivos, usar backend aggregation functions
    repo
        .watchCiclosActivos(productoraId)
        .listen(
          (ciclos) {
            if (mounted) {
              // Al recibir nuevos datos, actualizamos la lista maestra y reaplicamos filtros
              state = state.copyWith(ciclos: ciclos, isLoading: false);
              _applyFilters();
              _calculateInventario();
              _calculateProyecciones();
            }
          },
          onError: (error) {
            if (mounted) {
              state = state.copyWith(isLoading: false, error: error.toString());
            }
          },
        );
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(fechaInicio: start, fechaFin: end);
    _applyFilters();
  }

  void setCintaFilter(String? colorHex) {
    state = ConsultasState(
      isLoading: state.isLoading,
      ciclos: state.ciclos,
      ciclosFiltrados: state.ciclosFiltrados,
      fechaInicio: state.fechaInicio,
      fechaFin: state.fechaFin,
      cintaFilter: colorHex,
      variedadFilter: state.variedadFilter,
      loteFilter: state.loteFilter,
      totalEncintado: state.totalEncintado,
      totalCosechado: state.totalCosechado,
      totalCiclos: state.totalCiclos,
      semanasParaCosecha: state.semanasParaCosecha,
      proximasCosechas: state.proximasCosechas,
      inventario: state.inventario,
      totalInventario: state.totalInventario,
    );
    _applyFilters();
  }

  void setVariedadFilter(String? variedad) {
    state = ConsultasState(
      isLoading: state.isLoading,
      ciclos: state.ciclos,
      ciclosFiltrados: state.ciclosFiltrados,
      fechaInicio: state.fechaInicio,
      fechaFin: state.fechaFin,
      cintaFilter: state.cintaFilter,
      variedadFilter: variedad,
      loteFilter: state.loteFilter,
      totalEncintado: state.totalEncintado,
      totalCosechado: state.totalCosechado,
      totalCiclos: state.totalCiclos,
      semanasParaCosecha: state.semanasParaCosecha,
      proximasCosechas: state.proximasCosechas,
      inventario: state.inventario,
      totalInventario: state.totalInventario,
    );
    _applyFilters();
  }

  void setLoteFilter(String? lote) {
    state = state.copyWith(loteFilter: lote);
    _applyFilters();
  }

  void clearFilters() {
    state = ConsultasState(
      isLoading: state.isLoading,
      ciclos: state.ciclos,
      ciclosFiltrados: state.ciclos,
      fechaInicio: null,
      fechaFin: null,
      cintaFilter: null,
      variedadFilter: null,
      loteFilter: null,
      totalEncintado: state.totalEncintado,
      totalCosechado: state.totalCosechado,
      totalCiclos: state.totalCiclos,
      semanasParaCosecha: state.semanasParaCosecha,
      proximasCosechas: state.proximasCosechas,
      inventario: state.inventario,
      totalInventario: state.totalInventario,
    );
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = state.ciclos;

    // 1. Filtro de Fecha (Siembra)
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

    // 4. Filtro de Lote
    if (state.loteFilter != null && state.loteFilter!.isNotEmpty) {
      filtered = filtered
          .where((c) => c.nombreLote == state.loteFilter)
          .toList();
    }

    _calculateTotals(filtered);
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

  /// Calcula inventario: ciclos cosechados pendientes de entrega a empacadora
  void _calculateInventario() {
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
      (sum, c) => sum + (c.cantidadCosecha ?? 0),
    );
    state = state.copyWith(inventario: inv, totalInventario: total);
  }

  /// Calcula proyecciones de cosecha para ciclos encintados
  void _calculateProyecciones() {
    final now = DateTime.now();
    final semanas = state.semanasParaCosecha;
    final List<ProximaCosechaLocal> proyecciones = [];

    for (var ciclo
        in state.inventario.isEmpty
            ? state.ciclos.where((c) => c.estado == EstadoCiclo.encintado)
            : state.inventario) {
      final fecha = ciclo.proyeccionCosecha(semanas);
      if (fecha != null) {
        proyecciones.add(
          ProximaCosechaLocal(
            ciclo: ciclo,
            fechaProyectada: fecha,
            diasRestantes: fecha.difference(now).inDays,
          ),
        );
      }
    }

    // Ordenar por fecha proyectada (más próxima primero)
    proyecciones.sort((a, b) => a.fechaProyectada.compareTo(b.fechaProyectada));

    state = state.copyWith(proximasCosechas: proyecciones);
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
