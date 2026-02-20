import '../entities/cinta.dart';
import '../entities/variedad.dart';
import '../entities/finca.dart';
import '../entities/lote.dart';

abstract class IAdministracionRepository {
  // Cintas
  Future<void> saveCinta(Cinta cinta);
  Stream<List<Cinta>> watchCintas({String? productoraId});
  Future<void> deleteCinta(String id);

  // Variedades
  Future<void> saveVariedad(Variedad variedad);
  Stream<List<Variedad>> watchVariedades({String? productoraId});
  Future<void> deleteVariedad(String id);

  // Fincas
  Future<void> saveFinca(Finca finca);
  Stream<List<Finca>> watchFincas();
  Future<Finca?> getFincaById(String id);
  Future<void> deleteFinca(String id);

  // Lotes
  Future<void> saveLote(Lote lote);
  Stream<List<Lote>> watchLotesByFinca(String fincaId);
  Future<List<Lote>> getLotesByFincaFuture(String fincaId);
  Stream<List<Lote>> watchAllLotes();
  Future<void> deleteLote(String id);
}
