import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';
import '../../domain/repositories/produccion_repository.dart';
import '../datasources/produccion_remote_datasource.dart';

class ProduccionRepositoryImpl implements ProduccionRepository {
  final ProduccionRemoteDatasource _datasource;

  ProduccionRepositoryImpl(this._datasource);

  // ═══════════════════════════════════════════════════════
  //  LOTES
  // ═══════════════════════════════════════════════════════

  @override
  Stream<List<Lote>> watchLotes(String productoraId) {
    return _datasource.watchLotes(productoraId);
  }

  @override
  Future<Result<Lote>> crearLote({
    required String nombre,
    required double area,
    required String variedad,
    required String productoraId,
  }) async {
    try {
      final lote = await _datasource.crearLote(
        nombre: nombre,
        area: area,
        variedad: variedad,
        productoraId: productoraId,
      );
      return Success(lote);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure('Error al crear lote: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  CICLOS
  // ═══════════════════════════════════════════════════════

  @override
  Stream<List<CicloProduccion>> watchCiclos(String productoraId) {
    return _datasource.watchCiclos(productoraId);
  }

  @override
  Future<Result<CicloProduccion>> getCicloActivo(
    String productoraId,
    String idLote,
  ) async {
    try {
      final ciclo = await _datasource.getCicloActivo(productoraId, idLote);
      if (ciclo == null) {
        return const FailureResult(
          NotFoundFailure('No hay ciclo activo para este lote'),
        );
      }
      return Success(ciclo);
    } catch (e) {
      return FailureResult(ServerFailure('Error al buscar ciclo: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  EVENTOS DEL CICLO
  // ═══════════════════════════════════════════════════════

  @override
  Future<Result<CicloProduccion>> registrarApertura({
    required String idLote,
    required String nombreLote,
    required double area,
    required String variedad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    try {
      final ciclo = await _datasource.registrarApertura(
        idLote: idLote,
        nombreLote: nombreLote,
        area: area,
        variedad: variedad,
        productoraId: productoraId,
        uidUsuario: uidUsuario,
      );
      return Success(ciclo);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure('Error al registrar apertura: $e'));
    }
  }

  @override
  Future<Result<CicloProduccion>> registrarEncintado({
    required String idCiclo,
    required ColorCinta colorCinta,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    try {
      final ciclo = await _datasource.registrarEncintado(
        idCiclo: idCiclo,
        colorCinta: colorCinta,
        cantidad: cantidad,
        productoraId: productoraId,
        uidUsuario: uidUsuario,
      );
      return Success(ciclo);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure('Error al registrar encintado: $e'));
    }
  }

  @override
  Future<Result<CicloProduccion>> registrarCosecha({
    required String idCiclo,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    try {
      final ciclo = await _datasource.registrarCosecha(
        idCiclo: idCiclo,
        cantidad: cantidad,
        productoraId: productoraId,
        uidUsuario: uidUsuario,
      );
      return Success(ciclo);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure('Error al registrar cosecha: $e'));
    }
  }
}
