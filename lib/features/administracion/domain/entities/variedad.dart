class Variedad {
  final String id;
  final String nombre;
  final String descripcion;
  final String productoraId;
  final bool esCultivoContinuo;

  const Variedad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.productoraId,
    this.esCultivoContinuo =
        true, // Por defecto asumimos Banano/Plátano por compatibilidad
  });
}
