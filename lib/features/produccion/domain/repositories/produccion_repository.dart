import '../../../../core/errors/result.dart';
import '../entities/lote.dart';
import '../../../administracion/domain/entities/finca.dart';
import '../entities/ciclo_produccion.dart';
import '../entities/productora_stats.dart';

/// Contrato del repositorio de producción.
abstract class ProduccionRepository {
  // --- Lotes ---
  // --- Lotes & Fincas ---
  Stream<List<Lote>> watchLotes(String productoraId);
  Stream<List<Finca>> watchFincas(String productoraId);

  // --- Ciclos ---
  // --- Ciclos ---
  Stream<List<CicloProduccion>> watchCiclosActivos(String productoraId);

  Future<Result<List<CicloProduccion>>> getHistorialCiclos({
    required String productoraId,
    String? fincaId,
    String? loteId,
    int limit = 20,
    DateTime? lastDate,
  });

  Future<Result<CicloProduccion>> getCicloActivo(
    String productoraId,
    String idLote,
  );

  // --- Eventos del Ciclo ---
  Future<Result<CicloProduccion>> registrarSiembra({
    required String idLote,
    required String nombreLote,
    required double area,
    required String variedad,
    required String productoraId,
    required String uidUsuario,
  });

  Future<Result<CicloProduccion>> registrarEncintado({
    required String idCiclo,
    required String cintaId,
    required String cintaNombre,
    required String cintaColorHex,
    required double cantidad,
    required DateTime fecha,
    required String productoraId,
    required String uidUsuario,
  });

  Future<Result<CicloProduccion>> registrarCosecha({
    required String idCiclo,
    String? idEncintado, // Nullable para cultivos no-continuos
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  });

  // --- Estadísticas (Vista Previa) ---
  Future<Result<ProductoraStats>> getStatsProductora(String productoraId);
}
