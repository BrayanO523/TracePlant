import 'package:equatable/equatable.dart';
import 'produccion_enums.dart';

/// Entidad que representa un lote físico en la finca.
class Lote extends Equatable {
  final String id;
  final String nombre;
  final double area; // Área en manzanas o hectáreas
  final String variedad; // Variedad de cultivo
  final EstadoLote estado;
  final ColorCinta? colorCinta; // Color asignado al lote activo
  final String idProductora;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Lote({
    required this.id,
    required this.nombre,
    required this.area,
    required this.variedad,
    this.estado = EstadoLote.libre,
    this.colorCinta,
    required this.idProductora,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  @override
  List<Object?> get props => [
    id,
    nombre,
    area,
    variedad,
    estado,
    colorCinta,
    idProductora,
    fechaCreacion,
    fechaActualizacion,
  ];
}
