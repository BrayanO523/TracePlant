class Lote {
  final String id;
  final String nombre;
  final double area;
  final String fincaId;
  final String? variedadId;
  final String? variedadNombre;
  final String productoraId;
  final String estado;

  /// Coordenadas GPS del polígono del terreno.
  /// Cada elemento es un mapa con 'lat' y 'lng'.
  final List<Map<String, double>> coordenadas;

  const Lote({
    required this.id,
    required this.nombre,
    required this.area,
    required this.fincaId,
    this.variedadId,
    this.variedadNombre,
    required this.productoraId,
    required this.estado,
    this.coordenadas = const [],
  });

  String get variedad => variedadNombre ?? 'Sin Variedad';

  /// true si el lote tiene polígono mapeado
  bool get tieneMapa => coordenadas.length >= 3;
}
