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
  Stream<List<CicloProduccion>> watchCiclos(String productoraId);
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
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  });

  // --- Estadísticas (Vista Previa) ---
  Future<Result<ProductoraStats>> getStatsProductora(String productoraId);
}
