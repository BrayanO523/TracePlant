import 'package:equatable/equatable.dart';
import 'produccion_enums.dart';

/// Entidad que representa un evento individual en el ciclo de producción.
class EventoCampo extends Equatable {
  final String id;
  final TipoEvento tipo;
  final String idCiclo;
  final String idLote;
  final double cantidad;
  final String? colorCinta;
  final String? observaciones;
  final String idProductora; // para auditoría del Admin
  final String uidRegistradoPor;
  final DateTime fechaEvento;
  final DateTime? fechaCreacion;

  const EventoCampo({
    required this.id,
    required this.tipo,
    required this.idCiclo,
    required this.idLote,
    required this.cantidad,
    this.colorCinta,
    this.observaciones,
    required this.idProductora,
    required this.uidRegistradoPor,
    required this.fechaEvento,
    this.fechaCreacion,
  });

  @override
  List<Object?> get props => [
    id,
    tipo,
    idCiclo,
    idLote,
    cantidad,
    colorCinta,
    observaciones,
    idProductora,
    uidRegistradoPor,
    fechaEvento,
  ];
}
