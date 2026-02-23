/// Tipo de evento en el ciclo de producción
enum TipoEvento { siembra, encintado, cosecha }

/// Estado de un lote físico
enum EstadoLote { libre, ocupado }

/// Estado del ciclo de producción
enum EstadoCiclo { sembrado, encintado, cosechado, cancelado }

/// Catálogo fijo de colores de cinta.
/// Cada color tiene un nombre para UI y un valor hex para visualización.
enum ColorCinta {
  rojo('Rojo', 0xFFE53935),
  azul('Azul', 0xFF1E88E5),
  verde('Verde', 0xFF43A047),
  amarillo('Amarillo', 0xFFFDD835),
  naranja('Naranja', 0xFFFB8C00),
  morado('Morado', 0xFF8E24AA),
  blanco('Blanco', 0xFFEEEEEE),
  negro('Negro', 0xFF212121),
  rosado('Rosado', 0xFFEC407A),
  celeste('Celeste', 0xFF29B6F6);

  final String label;
  final int colorValue;

  const ColorCinta(this.label, this.colorValue);

  /// Buscar por nombre (case-insensitive)
  static ColorCinta? fromString(String? value) {
    if (value == null) return null;
    try {
      return ColorCinta.values.firstWhere(
        (e) => e.name == value || e.label.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
