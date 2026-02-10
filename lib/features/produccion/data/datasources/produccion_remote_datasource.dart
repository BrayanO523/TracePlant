import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../models/lote_model.dart';
import '../models/ciclo_produccion_model.dart';
import '../../domain/entities/produccion_enums.dart';

/// Datasource remoto para operaciones de producción contra Firestore.
class ProduccionRemoteDatasource {
  final FirebaseFirestore _firestore;

  ProduccionRemoteDatasource(this._firestore);

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════

  CollectionReference _lotesRef() =>
      _firestore.collection(FirestorePaths.lotes);

  CollectionReference _ciclosRef() =>
      _firestore.collection(FirestorePaths.ciclosProduccion);

  // ═══════════════════════════════════════════════════════
  //  LOTES
  // ═══════════════════════════════════════════════════════

  Stream<List<LoteModel>> watchLotes(String productoraId) {
    return _lotesRef()
        .where('id_productora', isEqualTo: productoraId)
        .orderBy('nombre')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => LoteModel.fromFirestore(doc)).toList(),
        );
  }

  Future<LoteModel> crearLote({
    required String nombre,
    required double area,
    required String variedad,
    required String productoraId,
  }) async {
    // Verificar nombre único dentro de la productora
    final existing = await _lotesRef()
        .where('id_productora', isEqualTo: productoraId)
        .where('nombre', isEqualTo: nombre)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw const ValidationFailure('Ya existe un lote con ese nombre');
    }

    final docRef = _lotesRef().doc();

    final lote = LoteModel(
      id: docRef.id,
      nombre: nombre,
      area: area,
      variedad: variedad,
      estado: EstadoLote.libre,
      idProductora: productoraId,
    );

    await docRef.set(lote.toJsonCreate());
    return lote;
  }

  // ═══════════════════════════════════════════════════════
  //  CICLOS DE PRODUCCIÓN
  // ═══════════════════════════════════════════════════════

  Stream<List<CicloProduccionModel>> watchCiclos(String productoraId) {
    return _ciclosRef()
        .where('id_productora', isEqualTo: productoraId)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CicloProduccionModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<CicloProduccionModel?> getCicloActivo(
    String productoraId,
    String idLote,
  ) async {
    final snap = await _ciclosRef()
        .where('id_productora', isEqualTo: productoraId)
        .where('id_lote', isEqualTo: idLote)
        .where('estado', whereIn: ['abierto', 'encintado'])
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return CicloProduccionModel.fromFirestore(snap.docs.first);
  }

  // ═══════════════════════════════════════════════════════
  //  APERTURA
  // ═══════════════════════════════════════════════════════

  Future<CicloProduccionModel> registrarApertura({
    required String idLote,
    required String nombreLote,
    required double area,
    required String variedad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    final cicloActivo = await getCicloActivo(productoraId, idLote);
    if (cicloActivo != null) {
      throw const ValidationFailure(
        'Este lote ya tiene un ciclo activo. Debe cosecharlo primero.',
      );
    }

    final now = DateTime.now();
    final cicloRef = _ciclosRef().doc();
    final idCiclo = cicloRef.id;

    final ciclo = CicloProduccionModel(
      id: idCiclo,
      idLote: idLote,
      nombreLote: nombreLote,
      idProductora: productoraId,
      estado: EstadoCiclo.abierto,
      fechaApertura: now,
      area: area,
      variedad: variedad,
      uidRegistradoPor: uidUsuario,
    );

    final batch = _firestore.batch();

    batch.set(cicloRef, ciclo.toJsonCreate());

    // Cambiar estado del lote a OCUPADO
    final loteRef = _lotesRef().doc(idLote);
    batch.update(loteRef, {
      'estado': EstadoLote.ocupado.name,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return ciclo;
  }

  // ═══════════════════════════════════════════════════════
  //  ENCINTADO
  // ═══════════════════════════════════════════════════════

  Future<CicloProduccionModel> registrarEncintado({
    required String idCiclo,
    required ColorCinta colorCinta,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    final cicloDoc = await _ciclosRef().doc(idCiclo).get();
    if (!cicloDoc.exists) {
      throw const NotFoundFailure('Ciclo de producción no encontrado');
    }

    final ciclo = CicloProduccionModel.fromFirestore(cicloDoc);

    if (ciclo.estado != EstadoCiclo.abierto) {
      throw const ValidationFailure(
        'Solo se puede encintar un ciclo en estado "Abierto"',
      );
    }

    final now = DateTime.now();

    final batch = _firestore.batch();

    // Actualizar ciclo
    batch.update(_ciclosRef().doc(idCiclo), {
      'estado': EstadoCiclo.encintado.name,
      'color_cinta': colorCinta.name,
      'cantidad_encintado': cantidad,
      'fecha_encintado': Timestamp.fromDate(now),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    // Actualizar lote con color de cinta
    final loteRef = _lotesRef().doc(ciclo.idLote);
    batch.update(loteRef, {
      'color_cinta': colorCinta.name,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return CicloProduccionModel(
      id: idCiclo,
      idLote: ciclo.idLote,
      nombreLote: ciclo.nombreLote,
      idProductora: productoraId,
      estado: EstadoCiclo.encintado,
      fechaApertura: ciclo.fechaApertura,
      area: ciclo.area,
      variedad: ciclo.variedad,
      colorCinta: colorCinta,
      cantidadEncintado: cantidad,
      uidRegistradoPor: uidUsuario,
      fechaEncintado: now,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  COSECHA
  // ═══════════════════════════════════════════════════════

  Future<CicloProduccionModel> registrarCosecha({
    required String idCiclo,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    final cicloDoc = await _ciclosRef().doc(idCiclo).get();
    if (!cicloDoc.exists) {
      throw const NotFoundFailure('Ciclo de producción no encontrado');
    }

    final ciclo = CicloProduccionModel.fromFirestore(cicloDoc);

    if (ciclo.estado != EstadoCiclo.encintado) {
      throw const ValidationFailure(
        'Solo se puede cosechar un ciclo en estado "Encintado"',
      );
    }

    final now = DateTime.now();

    final batch = _firestore.batch();

    batch.update(_ciclosRef().doc(idCiclo), {
      'estado': EstadoCiclo.cosechado.name,
      'cantidad_cosecha': cantidad,
      'fecha_cosecha': Timestamp.fromDate(now),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    // Liberar lote
    final loteRef = _lotesRef().doc(ciclo.idLote);
    batch.update(loteRef, {
      'estado': EstadoLote.libre.name,
      'color_cinta': null,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return CicloProduccionModel(
      id: idCiclo,
      idLote: ciclo.idLote,
      nombreLote: ciclo.nombreLote,
      idProductora: productoraId,
      estado: EstadoCiclo.cosechado,
      fechaApertura: ciclo.fechaApertura,
      area: ciclo.area,
      variedad: ciclo.variedad,
      colorCinta: ciclo.colorCinta,
      cantidadEncintado: ciclo.cantidadEncintado,
      cantidadCosecha: cantidad,
      uidRegistradoPor: uidUsuario,
      fechaEncintado: ciclo.fechaEncintado,
      fechaCosecha: now,
    );
  }
}
