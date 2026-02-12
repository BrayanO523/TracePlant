class ProductoraStats {
  final int ciclosActivos;
  final int lotesActivos;
  final double volumenCosecha; // Libras estimadas o reales
  final double volumenEncintado; // Libras estimadas o bultos

  const ProductoraStats({
    required this.ciclosActivos,
    required this.lotesActivos,
    required this.volumenCosecha,
    required this.volumenEncintado,
  });

  factory ProductoraStats.empty() => const ProductoraStats(
    ciclosActivos: 0,
    lotesActivos: 0,
    volumenCosecha: 0,
    volumenEncintado: 0,
  );
}
