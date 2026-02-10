import 'dart:ui' show Color;
import '../../domain/entities/produccion_enums.dart';

/// Extensión de presentación que añade soporte de Color de Flutter
/// al enum ColorCinta del dominio (que es pure Dart).
extension ColorCintaExt on ColorCinta {
  /// Convierte el valor hex almacenado en un Color de Flutter.
  Color get color => Color(colorValue);
}
