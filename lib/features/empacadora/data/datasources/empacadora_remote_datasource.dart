import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../produccion/data/models/ciclo_produccion_model.dart';
import '../../../productora/data/models/productora_model.dart';

/// Datasource remoto para el módulo de Empacadora.
///
/// Se encarga de realizar las lecturas agregadas (JOINs lógicos)
/// para obtener la información de las productoras asignadas por el Admin.
class EmpacadoraRemoteDatasource {
  final FirebaseFirestore _firestore;

  EmpacadoraRemoteDatasource(this._firestore);

  // ═══════════════════════════════════════════════════════
  //  CONSULTAS
  // ═══════════════════════════════════════════════════════

  /// Retorna las productoras asignadas a la empacadora [idEmpacadora].
  ///
  /// 1. Busca en colección `asignaciones` donde `id_empacadora` == [idEmpacadora]
  ///    y estado == 'activa'.
  /// 2. Obtiene los IDs de las productoras.
  /// 3. Busca los detalles de esas productoras en colección `productoras`.
  Future<List<ProductoraModel>> getProductorasAsignadas(
    String idEmpacadora,
  ) async {
    // 1. Obtener asignaciones activas
    final asignacionesSnap = await _firestore
        .collection(FirestorePaths.asignaciones)
        .where('id_empacadora', isEqualTo: idEmpacadora)
        .where('estado', isEqualTo: 'activa')
        .get();

    if (asignacionesSnap.docs.isEmpty) return [];

    final idsProductoras = asignacionesSnap.docs
        .map((d) => d['id_productora'] as String)
        .toSet() // Unicidad por seguridad
        .toList();

    if (idsProductoras.isEmpty) return [];

    // 2. Obtener detalles de productoras (usando whereIn con chunking si fuera necesario)
    // Firestore limita whereIn a 10. Si son más, idealmente se hace por partes.
    // Para este MVP asumimos < 10 asignaciones por empacadora por ahora,
    // o hacemos un loop simple.

    // Implementación robusta para > 10 IDs: dividir en chunks de 10
    final productoras = <ProductoraModel>[];

    for (var i = 0; i < idsProductoras.length; i += 10) {
      final chunk = idsProductoras.sublist(
        i,
        i + 10 > idsProductoras.length ? idsProductoras.length : i + 10,
      );

      final snap = await _firestore
          .collection(FirestorePaths.productoras)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      productoras.addAll(
        snap.docs.map((d) => ProductoraModel.fromFirestore(d)),
      );
    }

    return productoras;
  }

  /// Stream combinada de ciclos de múltiples productoras.
  ///
  /// Nota: Firestore no permite OR queries complejas en streams fácilmente
  /// sin índices compuestos específicos o limitaciones.
  /// Una estrategia eficiente es consultar `ciclos_produccion` donde
  /// `id_productora` esté en la lista [idsProductoras].
  Stream<List<CicloProduccionModel>> watchCiclosDeProductoras(
    List<String> idsProductoras,
  ) {
    if (idsProductoras.isEmpty) return Stream.value([]);

    // Firestore limita whereIn a 10 elementos.
    // Para > 10, se necesita merge de streams (fuera de alcance MVP).
    // Fallback: tomar los primeros 10.
    final ids = idsProductoras.length > 10
        ? idsProductoras.sublist(0, 10)
        : idsProductoras;

    return _firestore
        .collection(FirestorePaths.ciclosProduccion)
        .where('id_productora', whereIn: ids)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CicloProduccionModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Retorna un mapa loteId → nombreFinca para los lotes
  /// de las productoras indicadas.
  Future<Map<String, String>> fetchLoteFincaMap(
    List<String> idsProductoras,
  ) async {
    if (idsProductoras.isEmpty) return {};

    // 1. Obtener todos los lotes de las productoras
    final lotes = <Map<String, dynamic>>[];
    for (var i = 0; i < idsProductoras.length; i += 10) {
      final chunk = idsProductoras.sublist(
        i,
        i + 10 > idsProductoras.length ? idsProductoras.length : i + 10,
      );
      final snap = await _firestore
          .collection(FirestorePaths.lotes)
          .where('productoraId', whereIn: chunk)
          .get();
      for (var doc in snap.docs) {
        final data = doc.data();
        data['_id'] = doc.id;
        lotes.add(data);
      }
    }

    // 2. Obtener IDs únicos de fincas
    final fincaIds = lotes
        .map((l) => l['fincaId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    // 3. Obtener nombres de fincas
    final fincaNames = <String, String>{};
    for (var i = 0; i < fincaIds.length; i += 10) {
      final chunk = fincaIds.sublist(
        i,
        i + 10 > fincaIds.length ? fincaIds.length : i + 10,
      );
      final snap = await _firestore
          .collection(FirestorePaths.fincas)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snap.docs) {
        fincaNames[doc.id] = (doc.data()['nombre'] as String?) ?? '';
      }
    }

    // 4. Construir mapa loteId → nombreFinca
    final result = <String, String>{};
    for (var lote in lotes) {
      final loteId = lote['_id'] as String;
      final fincaId = lote['fincaId'] as String? ?? '';
      result[loteId] = fincaNames[fincaId] ?? '';
    }

    return result;
  }
}
