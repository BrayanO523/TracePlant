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

  // Lista de encintados (Nuevo)
  final List<DetalleEncintado> encintados;

  // Campos de cierre / cosecha
  final DateTime? fechaCosecha;
  final double? cantidadCosecha;
  final double? merma;
  final double? mermaPorcentaje;
  final String? uidRegistradoPor;
  final String? idEmpacadora;

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
    this.encintados = const [],
    this.fechaCosecha,
    this.cantidadCosecha,
    this.merma,
    this.mermaPorcentaje,
    this.uidRegistradoPor,
    this.idEmpacadora,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  // Helper para suma total encintado
  double get totalEncintado => encintados.fold(0, (sum, e) => sum + e.cantidad);
}
