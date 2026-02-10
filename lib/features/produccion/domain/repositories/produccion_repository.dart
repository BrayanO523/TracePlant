import '../../../../core/errors/result.dart';
import '../entities/lote.dart';
import '../entities/ciclo_produccion.dart';
import '../entities/produccion_enums.dart';

/// Contrato del repositorio de producción.
abstract class ProduccionRepository {
  // --- Lotes ---
  Stream<List<Lote>> watchLotes(String productoraId);
  Future<Result<Lote>> crearLote({
    required String nombre,
    required double area,
    required String variedad,
    required String productoraId,
  });

  // --- Ciclos ---
  Stream<List<CicloProduccion>> watchCiclos(String productoraId);
  Future<Result<CicloProduccion>> getCicloActivo(
    String productoraId,
    String idLote,
  );

  // --- Eventos del Ciclo ---
  Future<Result<CicloProduccion>> registrarApertura({
    required String idLote,
    required String nombreLote,
    required double area,
    required String variedad,
    required String productoraId,
    required String uidUsuario,
  });

  Future<Result<CicloProduccion>> registrarEncintado({
    required String idCiclo,
    required ColorCinta colorCinta,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  });

  Future<Result<CicloProduccion>> registrarCosecha({
    required String idCiclo,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  });
}
