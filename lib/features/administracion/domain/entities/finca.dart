class Finca {
  final String id;
  final String nombre;
  final String ubicacion;
  final double areaTotal;
  final String productoraId;
  final bool activo;

  const Finca({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.areaTotal,
    required this.productoraId,
    this.activo = true,
  });
}
