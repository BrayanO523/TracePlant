import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../models/lote_model.dart';
import '../models/ciclo_produccion_model.dart';
import '../../../administracion/data/models/finca_model.dart';
import '../../domain/entities/produccion_enums.dart';
import '../../domain/entities/detalle_encintado.dart';

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
        .where('productoraId', isEqualTo: productoraId)
        .orderBy('nombre')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => LoteModel.fromFirestore(doc)).toList(),
        );
  }

  // ═══════════════════════════════════════════════════════
  //  FINCAS (Read-Only for Production)
  // ═══════════════════════════════════════════════════════

  Stream<List<FincaModel>> watchFincas(String productoraId) {
    return _firestore
        .collection(FirestorePaths.fincas)
        .where('productoraId', isEqualTo: productoraId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => FincaModel.fromFirestore(doc))
              .where((f) => f.activo)
              .toList();
          list.sort((a, b) => a.nombre.compareTo(b.nombre));
          return list;
        });
  }

  // ═══════════════════════════════════════════════════════
  //  CICLOS DE PRODUCCIÓN
  // ═══════════════════════════════════════════════════════

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
        .where(
          'estado',
          whereIn: ['sembrado', 'encintado', 'abierto'],
        ) // Compatible con legacy
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return CicloProduccionModel.fromFirestore(snap.docs.first);
  }

  // ═══════════════════════════════════════════════════════
  //  SIEMBRA (Antes Apertura)
  // ═══════════════════════════════════════════════════════

  Future<CicloProduccionModel> registrarSiembra({
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
      estado: EstadoCiclo.sembrado,
      fechaSiembra: now,
      area: area,
      variedad: variedad,
      encintados: const [],
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
  //  ENCINTADO (Múltiple)
  // ═══════════════════════════════════════════════════════

  Future<CicloProduccionModel> registrarEncintado({
    required String idCiclo,
    required String cintaId,
    required String cintaNombre,
    required String cintaColorHex,
    required double cantidad,
    required DateTime fecha,
    required String productoraId,
    required String uidUsuario,
  }) async {
    final cicloDoc = await _ciclosRef().doc(idCiclo).get();
    if (!cicloDoc.exists) {
      throw const NotFoundFailure('Ciclo de producción no encontrado');
    }

    final ciclo = CicloProduccionModel.fromFirestore(cicloDoc);

    // Permitir encintar si está sembrado o ya encintado
    if (ciclo.estado != EstadoCiclo.sembrado &&
        ciclo.estado != EstadoCiclo.encintado) {
      throw const ValidationFailure(
        'Solo se puede encintar un ciclo activo (Sembrado o Encintado)',
      );
    }

    final nuevoEncintado = {
      'id': _firestore.collection('tmp').doc().id, // ID único generado
      'cinta_id': cintaId,
      'cinta_nombre': cintaNombre,
      'cinta_color_hex': cintaColorHex,
      'cantidad': cantidad,
      'fecha': fecha.millisecondsSinceEpoch,
      'usuario_id': uidUsuario,
    };

    final batch = _firestore.batch();

    // Agregar nuevo encintado a la lista y actualizar estado
    batch.update(_ciclosRef().doc(idCiclo), {
      'estado': EstadoCiclo.encintado.name, // Asegurar estado encintado
      'encintados': FieldValue.arrayUnion([nuevoEncintado]),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    // Actualizar lote con color de cinta (el último nombre de cinta encintado)
    final loteRef = _lotesRef().doc(ciclo.idLote);
    batch.update(loteRef, {
      'color_cinta':
          cintaNombre, // Guardamos el nombre para referencia visual rápida
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Retornamos el modelo actualizado (simulado para UI inmediata)
    return CicloProduccionModel(
      id: ciclo.id,
      idLote: ciclo.idLote,
      nombreLote: ciclo.nombreLote,
      idProductora: ciclo.idProductora,
      estado: EstadoCiclo.encintado,
      fechaSiembra: ciclo.fechaSiembra,
      area: ciclo.area,
      variedad: ciclo.variedad,
      encintados: [
        ...ciclo.encintados,
        DetalleEncintado.fromMap(nuevoEncintado),
      ],
      uidRegistradoPor: ciclo.uidRegistradoPor,
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

    // ── VALIDACIÓN: Verificar si tiene Empacadora Asignada ──
    final asignacionSnap = await _firestore
        .collection(FirestorePaths.asignaciones)
        .where('id_productora', isEqualTo: productoraId)
        .where('estado', isEqualTo: 'activa')
        .limit(1)
        .get();

    if (asignacionSnap.docs.isEmpty) {
      throw const ValidationFailure(
        'No tiene una empacadora asignada actualmente. Contacte al administrador para poder entregar su cosecha.',
      );
    }

    final idEmpacadora =
        asignacionSnap.docs.first.get('id_empacadora') as String;

    final now = DateTime.now();

    final batch = _firestore.batch();

    final cantidadEncintadoTotal = ciclo.totalEncintado;
    final merma = cantidadEncintadoTotal - cantidad;
    final mermaPorcentaje = cantidadEncintadoTotal > 0
        ? (merma / cantidadEncintadoTotal) * 100
        : 0.0;

    batch.update(_ciclosRef().doc(idCiclo), {
      'estado': EstadoCiclo.cosechado.name,
      'cantidad_cosecha': cantidad,
      'merma': merma,
      'merma_porcentaje': mermaPorcentaje,
      'id_empacadora': idEmpacadora,
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
      fechaSiembra: ciclo.fechaSiembra,
      area: ciclo.area,
      variedad: ciclo.variedad,
      encintados: ciclo.encintados,
      cantidadCosecha: cantidad,
      merma: merma,
      mermaPorcentaje: mermaPorcentaje,
      idEmpacadora: idEmpacadora,
      uidRegistradoPor: uidUsuario,
      fechaCosecha: now,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ENTREGA A EMPACADORA
  // ═══════════════════════════════════════════════════════

  Future<CicloProduccionModel> registrarEntrega({
    required String idCiclo,
    required String productoraId,
    required String uidUsuario,
  }) async {
    final cicloDoc = await _ciclosRef().doc(idCiclo).get();
    if (!cicloDoc.exists) {
      throw const NotFoundFailure('Ciclo de producción no encontrado');
    }

    final ciclo = CicloProduccionModel.fromFirestore(cicloDoc);

    if (ciclo.estado != EstadoCiclo.cosechado) {
      throw const ValidationFailure(
        'Solo se puede entregar un ciclo en estado "Cosechado"',
      );
    }

    final now = DateTime.now();

    await _ciclosRef().doc(idCiclo).update({
      'estado': EstadoCiclo.entregado.name,
      'fecha_entrega': Timestamp.fromDate(now),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });

    return CicloProduccionModel(
      id: idCiclo,
      idLote: ciclo.idLote,
      nombreLote: ciclo.nombreLote,
      idProductora: productoraId,
      estado: EstadoCiclo.entregado,
      fechaSiembra: ciclo.fechaSiembra,
      area: ciclo.area,
      variedad: ciclo.variedad,
      encintados: ciclo.encintados,
      cantidadCosecha: ciclo.cantidadCosecha,
      merma: ciclo.merma,
      mermaPorcentaje: ciclo.mermaPorcentaje,
      idEmpacadora: ciclo.idEmpacadora,
      uidRegistradoPor: uidUsuario,
      fechaCosecha: ciclo.fechaCosecha,
      fechaEntrega: now,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ESTADÍSTICAS (VISTA PREVIA)
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStatsProductora(String productoraId) async {
    final snap = await _ciclosRef()
        .where('id_productora', isEqualTo: productoraId)
        .get();

    int ciclosActivos = 0;
    int lotesActivos = 0;
    double volumenCosecha = 0;
    double volumenEncintado = 0;
    final Set<String> lotesIds = {};

    for (final doc in snap.docs) {
      final ciclo = CicloProduccionModel.fromFirestore(doc);

      // Saltar ciclos cancelados (filtro client-side)
      if (ciclo.estado == EstadoCiclo.cancelado) continue;

      // Contar ciclos activos (sembrado + encintado, no cosechado/entregado)
      if (ciclo.estado != EstadoCiclo.cosechado &&
          ciclo.estado != EstadoCiclo.entregado) {
        ciclosActivos++;
        lotesIds.add(ciclo.idLote);
      }

      // Volumen Cosecha (Histórico Total): Todo lo que ya se cortó.
      volumenCosecha += ciclo.cantidadCosecha ?? 0;

      // Volumen En Cinta (Inventario Activo): Solo lo que está ACTUALMENTE madurando en el campo.
      if (ciclo.estado == EstadoCiclo.encintado) {
        volumenEncintado += ciclo.totalEncintado;
      }
    }

    lotesActivos = lotesIds.length;

    return {
      'ciclosActivos': ciclosActivos,
      'lotesActivos': lotesActivos,
      'volumenCosecha': volumenCosecha,
      'volumenEncintado': volumenEncintado,
    };
  }
}
