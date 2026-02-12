class Lote {
  final String id;
  final String nombre;
  final double area;
  final String fincaId;
  final String? variedadId;
  final String? variedadNombre;
  final String productoraId;
  final String estado;

  const Lote({
    required this.id,
    required this.nombre,
    required this.area,
    required this.fincaId,
    this.variedadId,
    this.variedadNombre,
    required this.productoraId,
    required this.estado,
  });

  String get variedad => variedadNombre ?? 'Sin Variedad';
}
