import 'package:flutter/material.dart';

/// Fuente única de verdad para todos los colores de TracePlant.
///
/// Para cambiar un color en toda la app, basta editarlo aquí.
/// Uso: `AppColors.primary`, `AppColors.estadoSembrado`, etc.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════
  //  PALETA PRINCIPAL (Natural/Agrícola)
  // ═══════════════════════════════════════════════════════

  /// Verde bosque — color principal de la app
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF43A047);
  static const Color primarySurface = Color(0xFFE8F5E9); // Verde muy suave

  /// Ámbar cosecha — acento secundario
  static const Color secondary = Color(0xFFF9A825);
  static const Color secondaryDark = Color(0xFFF57F17);
  static const Color secondaryLight = Color(0xFFFFF176);

  /// Tierra — acento terciario
  static const Color tertiary = Color(0xFF6D4C41);
  static const Color tertiaryLight = Color(0xFF8D6E63);

  // ═══════════════════════════════════════════════════════
  //  FONDOS Y SUPERFICIES
  // ═══════════════════════════════════════════════════════

  /// Fondo general de la app (gris verdoso cálido)
  static const Color background = Color(0xFFF5F7F0);

  /// Fondo de cards/contenedores
  static const Color surface = Colors.white;

  /// Fondo de inputs / campos
  static const Color inputFill = Color(0xFFF9FAFB); // Gris 50

  /// Fondo alternativo suave para secciones
  static const Color surfaceVariant = Color(0xFFF5F7FA);

  // ═══════════════════════════════════════════════════════
  //  TEXTOS
  // ═══════════════════════════════════════════════════════

  /// Texto principal (títulos, encabezados)
  static const Color textPrimary = Color(0xFF1F2937); // Gray 800

  /// Texto secundario (subtítulos, descripciones)
  static const Color textSecondary = Color(0xFF4B5563); // Gray 600

  /// Texto deshabilitado / placeholder
  static const Color textHint = Color(0xFF9CA3AF); // Gray 400

  /// Texto terciario (metadata, fechas)
  static const Color textTertiary = Color(0xFF6B7280); // Gray 500

  // ═══════════════════════════════════════════════════════
  //  ESTADOS DE CICLO DE PRODUCCIÓN
  // ═══════════════════════════════════════════════════════

  /// Sembrado — ámbar
  static const Color estadoSembrado = Color(0xFFF9A825);

  /// Encintado — azul
  static const Color estadoEncintado = Color(0xFF1E88E5);

  /// Cosechado — verde
  static const Color estadoCosechado = Color(0xFF43A047);

  /// Entregado — azul oscuro (despacho a empacadora)
  static const Color estadoEntregado = Color(0xFF0277BD);

  /// Cancelado — rojo
  static const Color estadoCancelado = Color(0xFFE53935);

  // ═══════════════════════════════════════════════════════
  //  FEEDBACK / ACCIONES
  // ═══════════════════════════════════════════════════════

  /// Éxito
  static const Color success = Color(0xFF43A047);
  static const Color successSurface = Color(0xFFE8F5E9);

  /// Error / Peligro
  static const Color error = Color(0xFFE53935);
  static const Color errorSurface = Color(0xFFFFEBEE);

  /// Advertencia
  static const Color warning = Color(0xFFF9A825);
  static const Color warningSurface = Color(0xFFFFF8E1);

  /// Info
  static const Color info = Color(0xFF1E88E5);
  static const Color infoSurface = Color(0xFFE3F2FD);

  // ═══════════════════════════════════════════════════════
  //  CONSULTAS / FILTROS
  // ═══════════════════════════════════════════════════════

  /// Acento esmeralda para consultas
  static const Color accent = Color(0xFF00695C);
  static const Color accentSurface = Color(0xFFE0F2F1); // Teal 50
  static const Color accentBright = Color(0xFF00C853);

  // ═══════════════════════════════════════════════════════
  //  BORDES Y DIVISORES
  // ═══════════════════════════════════════════════════════

  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color borderLight = Color(0xFFF3F4F6); // Gray 100
  static const Color divider = Color(0xFFE5E7EB);

  // ═══════════════════════════════════════════════════════
  //  GRADIENTES
  // ═══════════════════════════════════════════════════════

  /// Gradiente principal (oscuro arriba → claro abajo)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
      Color(0xFF43A047),
    ],
  );

  /// Gradiente del login (claro arriba → oscuro abajo)
  /// El verde suave en la parte superior permite que el logo se vea nítido.
  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8F5E9), // Verde muy suave (casi blanco)
      Color(0xFFC8E6C9), // Verde suave
      Color(0xFFA5D6A7), // Verde claro
      Color(0xFF4CAF50), // Verde medio
      Color(0xFF2E7D32), // Verde bosque
      Color(0xFF1B5E20), // Verde oscuro
    ],
    stops: [0.0, 0.3, 0.5, 0.7, 0.85, 1.0],
  );

  /// Gradiente para cards destacadas
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00695C), Color(0xFF00897B)],
  );

  // ═══════════════════════════════════════════════════════
  //  DARK MODE (valores base)
  // ═══════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF121A12);
  static const Color darkSurface = Color(0xFF1E2D1E);
  static const Color darkTextPrimary = Color(0xFFE8F5E9);
  static const Color darkTextSecondary = Color(0xFFA5D6A7);
}
