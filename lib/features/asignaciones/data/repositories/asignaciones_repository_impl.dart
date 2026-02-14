import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../productora/domain/entities/productora.dart';
import '../../../empacadora/domain/entities/empacadora.dart';
import '../../domain/entities/asignacion.dart';
import '../../domain/repositories/asignaciones_repository.dart';
import '../datasources/asignaciones_remote_datasource.dart';

/// Implementación concreta del repositorio de asignaciones.
///
/// Traduce excepciones del datasource a [Result] para consumo
/// seguro desde el ViewModel.
class AsignacionesRepositoryImpl implements AsignacionesRepository {
  final AsignacionesRemoteDatasource _datasource;

  AsignacionesRepositoryImpl(this._datasource);

  @override
  Stream<List<Asignacion>> watchAsignacionesActivas() {
    return _datasource.watchAsignacionesActivas();
  }

  @override
  Future<List<Productora>> getProductorasDisponibles() {
    return _datasource.getProductorasDisponibles();
  }

  @override
  Future<List<Empacadora>> getEmpacadorasActivas() {
    return _datasource.getEmpacadorasActivas();
  }

  @override
  Future<Result<void>> crearAsignacion({
    required String idEmpacadora,
    required String idProductora,
  }) async {
    try {
      await _datasource.crearAsignacion(
        idEmpacadora: idEmpacadora,
        idProductora: idProductora,
      );
      return const Success(null);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> crearAsignacionesBatch({
    required String idEmpacadora,
    required List<String> idsProductoras,
  }) async {
    try {
      await _datasource.crearAsignacionesBatch(
        idEmpacadora: idEmpacadora,
        idsProductoras: idsProductoras,
      );
      return const Success(null);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> finalizarAsignacion(String idAsignacion) async {
    try {
      await _datasource.finalizarAsignacion(idAsignacion);
      return const Success(null);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
