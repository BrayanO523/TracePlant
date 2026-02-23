import 'detalle_encintado.dart';
import 'produccion_enums.dart';

class CicloProduccion {
  final String id;
  final String idLote;
  final String nombreLote;
  final String idProductora;
  final EstadoCiclo estado;
  final DateTime fechaSiembra; // Antes fechaApertura
  final double area;
  final String variedad;
  final bool esCultivoContinuo;

  // Lista de encintados (Nuevo)
  final List<DetalleEncintado> encintados;

  // Campos de cierre / cosecha
  final DateTime? fechaCosecha;
  final double? cantidadCosecha;
  final double? merma;
  final double? mermaPorcentaje;
  final String? uidRegistradoPor;
  final String? idEmpacadora;
  final DateTime? fechaEntrega;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const CicloProduccion({
    required this.id,
    required this.idLote,
    required this.nombreLote,
    required this.idProductora,
    required this.estado,
    required this.fechaSiembra,
    required this.area,
    required this.variedad,
    this.esCultivoContinuo = true, // Por defecto para retrocompatibilidad
    this.encintados = const [],
    this.fechaCosecha,
    this.cantidadCosecha,
    this.merma,
    this.mermaPorcentaje,
    this.uidRegistradoPor,
    this.idEmpacadora,
    this.fechaEntrega,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  // Helper para suma total encintado
  double get totalEncintado => encintados.fold(0, (sum, e) => sum + e.cantidad);

  /// true si el ciclo fue cosechado pero NO entregado a empacadora
  bool get pendienteEntrega => estado == EstadoCiclo.cosechado;

  /// Fecha del último encintado registrado (null si no hay encintados)
  DateTime? get ultimoEncintadoFecha {
    if (encintados.isEmpty) return null;
    return encintados.reduce((a, b) => a.fecha.isAfter(b.fecha) ? a : b).fecha;
  }

  /// Proyección de cosecha: último encintado + (semanas × 7 días)
  /// Retorna null si no hay encintados o ya se cosechó
  DateTime? proyeccionCosecha(int semanasParaCosecha) {
    if (fechaCosecha != null) return null; // Ya cosechado
    final ultima = ultimoEncintadoFecha;
    if (ultima == null) return null;
    return ultima.add(Duration(days: semanasParaCosecha * 7));
  }
}
