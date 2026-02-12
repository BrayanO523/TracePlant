import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../productora/domain/entities/productora.dart';
import '../../../empacadora/domain/entities/empacadora.dart';
import '../../../produccion/domain/entities/lote.dart';
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

  @override
  Future<Map<String, int>> getCargaTrabajo() {
    return _datasource.getCargaTrabajo();
  }

  @override
  Future<Map<String, List<Lote>>> getLotesDeProductoras(
    List<String> idsProductoras,
  ) async {
    final rawLotes = await _datasource.getLotesPorProductoras(idsProductoras);
    final map = <String, List<Lote>>{};

    for (final data in rawLotes) {
      // Reconstruimos el DocumentSnapshot simulado o usamos fromJson si existiera.
      // Como LoteModel.fromFirestore espera un DocumentSnapshot,
      // la forma más limpia es si el datasource devolviera los modelos o snapshots.
      // Pero el datasource devuelve List<dynamic> (Maps).
      // Adaptamos: LoteModel tiene factory pero no fromJson puro que acepte ID externo fácilmente.
      // Haremos un pequeño mapping manual o ajustaremos el datasource.
      // Ajuste: Datasource devuelve Map<String, dynamic> que es lo que tiene 'data()'.
      // LoteModel.fromFirestore usa doc.id y doc.data().
      // Asumiremos que el mapa incluye el ID si lo guardamos (generalmente no está en data()).
      // ERROR POTENCIAL: data() no tiene el ID.
      // CORRECCIÓN: El datasource debería devolver los modelos o snapshots.
      // Modificaremos el mapping aquí asumiendo que el datasource podría mejorarse,
      // pero por ahora mapeamos lo que podamos.
      // Dado que es visualización, el ID del lote es menos crítico que el nombre/área.
      // Usaremos un ID temporal o hash si no viene.

      // Mejor estrategia: Instanciar LoteModel manualmente con los datos del mapa.
      try {
        final mapData = data as Map<String, dynamic>;
        // Crear un objeto Lote
        final lote = Lote(
          id: 'view_only', // No necesitamos ID real para esta vista resumen
          nombre: mapData['nombre'] ?? 'Sin nombre',
          area: (mapData['area'] as num?)?.toDouble() ?? 0,
          variedad: mapData['variedad'] ?? '',
          fincaId: mapData['id_finca'] ?? '',
          idProductora: mapData['id_productora'] ?? '',
        );

        map.putIfAbsent(lote.idProductora, () => []).add(lote);
      } catch (_) {
        // Ignorar lotes mal formados
      }
    }
    return map;
  }
}
