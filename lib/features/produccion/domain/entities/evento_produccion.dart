class EventoProduccion {
  final String id;
  final String cicloId;
  final String tipo; // ENCINTADO, COSECHA
  final String colorId; // ID de la Cinta
  final int cantidad;
  final DateTime fecha;
  final String usuarioId;

  const EventoProduccion({
    required this.id,
    required this.cicloId,
    required this.tipo,
    required this.colorId,
    required this.cantidad,
    required this.fecha,
    required this.usuarioId,
  });
}
