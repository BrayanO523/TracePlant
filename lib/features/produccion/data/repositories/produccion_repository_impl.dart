import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/productora_stats.dart';
import '../../domain/repositories/produccion_repository.dart';
import '../../../administracion/domain/entities/finca.dart';
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
  Stream<List<Finca>> watchFincas(String productoraId) {
    return _datasource.watchFincas(productoraId);
  }

  // ═══════════════════════════════════════════════════════
  //  CICLOS
  // ═══════════════════════════════════════════════════════

  @override
  Stream<List<CicloProduccion>> watchCiclosActivos(String productoraId) {
    return _datasource.watchCiclosActivos(productoraId);
  }

  @override
  Future<Result<List<CicloProduccion>>> getHistorialCiclos({
    required String productoraId,
    String? fincaId,
    String? loteId,
    int limit = 20,
    DateTime? lastDate,
  }) async {
    try {
      final lista = await _datasource.getHistorialCiclos(
        productoraId: productoraId,
        fincaId: fincaId,
        loteId: loteId,
        limit: limit,
        lastDate: lastDate,
      );
      return Success(lista);
    } catch (e) {
      return FailureResult(ServerFailure('Error al cargar historial: $e'));
    }
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
  Future<Result<CicloProduccion>> registrarSiembra({
    required String idLote,
    required String nombreLote,
    required double area,
    required String variedad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    try {
      final ciclo = await _datasource.registrarSiembra(
        idLote: idLote,
        nombreLote: nombreLote,
        area: area,
        variedad: variedad,
        productoraId: productoraId,
        uidUsuario: uidUsuario,
      );

      // Sincronizar variedad → documento del lote en Firestore
      try {
        await FirebaseFirestore.instance.collection('lotes').doc(idLote).update(
          {'variedad': variedad, 'variedadNombre': variedad},
        );
      } catch (_) {
        // No bloquear si el update falla (el ciclo ya se creó bien)
      }

      return Success(ciclo);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure('Error al registrar siembra: $e'));
    }
  }

  @override
  Future<Result<CicloProduccion>> registrarEncintado({
    required String idCiclo,
    required String cintaId,
    required String cintaNombre,
    required String cintaColorHex,
    required double cantidad,
    required DateTime fecha,
    required String productoraId,
    required String uidUsuario,
  }) async {
    try {
      final ciclo = await _datasource.registrarEncintado(
        idCiclo: idCiclo,
        cintaId: cintaId,
        cintaNombre: cintaNombre,
        cintaColorHex: cintaColorHex,
        cantidad: cantidad,
        fecha: fecha,
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
    String? idEncintado,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    try {
      final ciclo = await _datasource.registrarCosecha(
        idCiclo: idCiclo,
        idEncintado: idEncintado,
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

  @override
  Future<Result<ProductoraStats>> getStatsProductora(
    String productoraId,
  ) async {
    try {
      final statsMap = await _datasource.getStatsProductora(productoraId);
      return Success(
        ProductoraStats(
          ciclosActivos: statsMap['ciclosActivos'] as int,
          lotesActivos: statsMap['lotesActivos'] as int,
          volumenCosecha: statsMap['volumenCosecha'] as double,
          volumenEncintado: statsMap['volumenEncintado'] as double,
        ),
      );
    } catch (e) {
      // Si falla, retornamos stats vacíos para no romper la UI, o error.
      // Preferible error para reintentar.
      return FailureResult(ServerFailure('Error al cargar estadísticas: $e'));
    }
  }
}
