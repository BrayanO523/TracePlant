import 'package:equatable/equatable.dart';
import 'asignacion_enums.dart';

/// Entidad de dominio: vínculo entre una Productora y una Empacadora.
///
/// Nombres denormalizados para evitar queries extras al renderizar listas.
class Asignacion extends Equatable {
  final String id;
  final String idEmpacadora;
  final String idProductora;
  final String nombreEmpacadora;
  final String nombreProductora;
  final EstadoAsignacion estado;
  final DateTime fechaAsignacion;
  final DateTime? fechaFinalizacion;

  const Asignacion({
    required this.id,
    required this.idEmpacadora,
    required this.idProductora,
    required this.nombreEmpacadora,
    required this.nombreProductora,
    required this.estado,
    required this.fechaAsignacion,
    this.fechaFinalizacion,
  });

  @override
  List<Object?> get props => [
    id,
    idEmpacadora,
    idProductora,
    estado,
    fechaAsignacion,
    fechaFinalizacion,
  ];
}
