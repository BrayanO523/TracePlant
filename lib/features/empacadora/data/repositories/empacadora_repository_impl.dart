import '../../../produccion/domain/entities/ciclo_produccion.dart';
import '../../../productora/domain/entities/productora.dart';
import '../../domain/repositories/empacadora_repository.dart';
import '../datasources/empacadora_remote_datasource.dart';

class EmpacadoraRepositoryImpl implements EmpacadoraRepository {
  final EmpacadoraRemoteDatasource _datasource;

  EmpacadoraRepositoryImpl(this._datasource);

  @override
  Future<List<Productora>> getProductorasAsignadas(String idEmpacadora) {
    // Aquí podríamos manejar excepciones y devolver Result,
    // pero la firma del repo retorna List directa (simplificada).
    // Si falla, lanzará excepción que el ViewModel debe manejar,
    // o cambiamos la firma a Future<Result<List>>.
    // Mantendremos consistencia con el estilo del proyecto.
    return _datasource.getProductorasAsignadas(idEmpacadora);
  }

  @override
  Stream<List<CicloProduccion>> watchCiclosDeProductoras(
    List<String> idsProductoras,
  ) {
    return _datasource.watchCiclosDeProductoras(idsProductoras);
  }

  @override
  Future<Map<String, String>> fetchLoteFincaMap(List<String> idsProductoras) {
    return _datasource.fetchLoteFincaMap(idsProductoras);
  }
}
