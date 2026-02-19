import '../../../produccion/domain/entities/ciclo_produccion.dart';
import '../../../productora/domain/entities/productora.dart';

/// Repositorio para la lectura agregada de datos por parte de la Empacadora.
///
/// La Empacadora NO crea asignaciones; solo lee las que el Admin le otorgó.
abstract class EmpacadoraRepository {
  /// Obtiene la lista de productoras que el Admin asignó a esta empacadora.
  Future<List<Productora>> getProductorasAsignadas(String idEmpacadora);

  /// Escucha en tiempo real los ciclos activos de las productoras asignadas.
  /// Se usa para calcular proyecciones de cosecha.
  Stream<List<CicloProduccion>> watchCiclosDeProductoras(
    List<String> idsProductoras,
  );

  /// Retorna un mapa loteId → nombreFinca para los lotes de las productoras.
  Future<Map<String, String>> fetchLoteFincaMap(List<String> idsProductoras);
}
