class Asignacion {
  final String id;
  final String productoraId;
  final String empacadoraId;
  final DateTime fechaAsignacion;
  final bool activo;

  const Asignacion({
    required this.id,
    required this.productoraId,
    required this.empacadoraId,
    required this.fechaAsignacion,
    required this.activo,
  });
}
