import 'package:equatable/equatable.dart';
import 'produccion_enums.dart';

/// Entidad que representa un ciclo completo de producción.
/// Flujo: Apertura → Encintado → Cosecha.
class CicloProduccion extends Equatable {
  final String id;
  final String idLote;
  final String nombreLote;
  final String idProductora;
  final EstadoCiclo estado;

  // ── Datos de Apertura ──
  final DateTime fechaApertura;
  final double area; // Área trabajada
  final String variedad; // Variedad de cultivo

  // ── Datos de Encintado ──
  final DateTime? fechaEncintado;
  final ColorCinta? colorCinta; // Enum de color fijo
  final double? cantidadEncintado;

  // ── Datos de Cosecha ──
  final DateTime? fechaCosecha;
  final double? cantidadCosecha;

  // ── Metadata ──
  final String? uidRegistradoPor;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const CicloProduccion({
    required this.id,
    required this.idLote,
    required this.nombreLote,
    required this.idProductora,
    this.estado = EstadoCiclo.abierto,
    required this.fechaApertura,
    required this.area,
    required this.variedad,
    this.fechaEncintado,
    this.colorCinta,
    this.cantidadEncintado,
    this.fechaCosecha,
    this.cantidadCosecha,
    this.uidRegistradoPor,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  /// Merma = Encintado - Cosecha (si ambos existen)
  double? get merma => cantidadEncintado != null && cantidadCosecha != null
      ? cantidadEncintado! - cantidadCosecha!
      : null;

  /// Porcentaje de merma
  double? get mermaPorcentaje => merma != null && cantidadEncintado! > 0
      ? (merma! / cantidadEncintado!) * 100
      : null;

  /// Si el ciclo permite registrar encintado
  bool get puedeEncintar => estado == EstadoCiclo.abierto;

  /// Si el ciclo permite registrar cosecha
  bool get puedeCosechar => estado == EstadoCiclo.encintado;

  @override
  List<Object?> get props => [
    id,
    idLote,
    nombreLote,
    idProductora,
    estado,
    fechaApertura,
    area,
    variedad,
    fechaEncintado,
    colorCinta,
    cantidadEncintado,
    fechaCosecha,
    cantidadCosecha,
    uidRegistradoPor,
  ];
}
