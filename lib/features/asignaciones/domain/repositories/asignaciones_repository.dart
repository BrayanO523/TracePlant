import '../../../../core/errors/result.dart';
import '../../../productora/domain/entities/productora.dart';
import '../../../empacadora/domain/entities/empacadora.dart';
import '../../../produccion/domain/entities/lote.dart';
import '../entities/asignacion.dart';

/// Contrato del repositorio de asignaciones.
///
/// Define las operaciones que el ViewModel puede ejecutar sin conocer
/// la implementación concreta (Firestore, REST, etc.).
abstract class AsignacionesRepository {
  /// Stream reactivo de todas las asignaciones activas.
  Stream<List<Asignacion>> watchAsignacionesActivas();

  /// Productoras que NO tienen asignación activa (disponibles para asignar).
  Future<List<Productora>> getProductorasDisponibles();

  /// Empacadoras activas (para el selector del Admin).
  Future<List<Empacadora>> getEmpacadorasActivas();

  /// Crea una asignación individual con validaciones de integridad.
  Future<Result<void>> crearAsignacion({
    required String idEmpacadora,
    required String idProductora,
  });

  /// Crea múltiples asignaciones en batch (multi-select).
  Future<Result<void>> crearAsignacionesBatch({
    required String idEmpacadora,
    required List<String> idsProductoras,
  });

  /// Finaliza una asignación, liberando la Productora.
  Future<Result<void>> finalizarAsignacion(String idAsignacion);

  /// Mapa de carga de trabajo: empacadoraId → cantidad de productoras asignadas.
  Future<Map<String, int>> getCargaTrabajo();

  /// Obtiene los lotes de las productoras especificadas (para detalle en UI).
  Future<Map<String, List<Lote>>> getLotesDeProductoras(
    List<String> idsProductoras,
  );
}
