import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/produccion_enums.dart';
import '../views/selectors/selector_lote_siembra_screen.dart';
import '../views/selectors/selector_ciclo_accion_screen.dart';

/// Clase utilitaria para manejar la lógica de selección en Acciones Rápidas.
/// Ahora redirige a pantallas completas con filtros avanzados.
class QuickActionsSelector {
  /// Muestra selector de lotes LIBRES para nueva siembra (Pantalla Completa)
  static void showSiembraSelector(
    BuildContext context,
    WidgetRef ref,
    String productoraId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorLoteSiembraScreen(productoraId: productoraId),
      ),
    );
  }

  /// Muestra selector de ciclos en SEMBRADO para encintar (Pantalla Completa)
  static void showEncintadoSelector(
    BuildContext context,
    WidgetRef ref,
    String productoraId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorCicloAccionScreen(
          productoraId: productoraId,
          tipoEvento: TipoEvento.encintado,
        ),
      ),
    );
  }

  /// Muestra selector de ciclos en ENCINTADO para cosechar (Pantalla Completa)
  static void showCosechaSelector(
    BuildContext context,
    WidgetRef ref,
    String productoraId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorCicloAccionScreen(
          productoraId: productoraId,
          tipoEvento: TipoEvento.cosecha,
        ),
      ),
    );
  }
}
