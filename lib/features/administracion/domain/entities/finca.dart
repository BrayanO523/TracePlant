class Finca {
  final String id;
  final String nombre;
  final String ubicacion;
  final double areaTotal;
  final String productoraId;
  final bool activo;

  /// Coordenadas GPS del polígono del terreno.
  /// Cada elemento es un mapa con 'lat' y 'lng'.
  final List<Map<String, double>> coordenadas;

  const Finca({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.areaTotal,
    required this.productoraId,
    this.activo = true,
    this.coordenadas = const [],
  });

  /// true si la finca tiene polígono mapeado
  bool get tieneMapa => coordenadas.length >= 3;
}
