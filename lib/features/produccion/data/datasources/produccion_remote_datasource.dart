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

  Stream<List<CicloProduccionModel>> watchCiclosActivos(String productoraId) {
    return _ciclosRef()
        .where('id_productora', isEqualTo: productoraId)
        .where(
          'estado',
          whereIn: ['sembrado', 'encintado', 'cosechado'],
        ) // SOLO activos
        .orderBy('fecha_siembra', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CicloProduccionModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<CicloProduccionModel>> getHistorialCiclos({
    required String productoraId,
    String? fincaId,
    String? loteId,
    int limit = 20,
    DateTime? lastDate,
  }) async {
    Query query = _ciclosRef()
        .where('id_productora', isEqualTo: productoraId)
        .where('estado', whereIn: ['entregado', 'cancelado']) // Solo inactivos
        .orderBy('fecha_siembra', descending: true)
        .limit(limit);

    if (loteId != null) {
      query = query.where('id_lote', isEqualTo: loteId);
    }

    if (lastDate != null) {
      // Usamos startAfter con el valor del campo orderBy
      query = query.startAfter([Timestamp.fromDate(lastDate)]);
    }

    // NOTA: Requiere índice compuesto (productora + estado + fecha)
    // y (productora + estado + lote + fecha)

    final snap = await query.get();
    return snap.docs
        .map((doc) => CicloProduccionModel.fromFirestore(doc))
        .toList();
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

    // ── OBTENER CONFIGURACIÓN DE VARIEDAD ──
    bool esCultivoContinuo = true; // Por defecto
    try {
      final varSnap = await _firestore
          .collection('variedades')
          .where('productoraId', isEqualTo: productoraId)
          .where('nombre', isEqualTo: variedad)
          .limit(1)
          .get();
      if (varSnap.docs.isNotEmpty) {
        esCultivoContinuo =
            varSnap.docs.first.data()['esCultivoContinuo'] as bool? ?? true;
      }
    } catch (_) {
      // Si falla, se queda con el default true
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
      esCultivoContinuo: esCultivoContinuo, // Asignar el flag correcto
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
    String? idEncintado,
    required double cantidad,
    required String productoraId,
    required String uidUsuario,
  }) async {
    final cicloDoc = await _ciclosRef().doc(idCiclo).get();
    if (!cicloDoc.exists) {
      throw const NotFoundFailure('Ciclo de producción no encontrado');
    }

    final ciclo = CicloProduccionModel.fromFirestore(cicloDoc);

    if (ciclo.estado != EstadoCiclo.encintado &&
        ciclo.estado != EstadoCiclo.sembrado) {
      throw const ValidationFailure(
        'Solo se puede cosechar un ciclo en estado "Sembrado" o "Encintado"',
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
    final cicloRef = _ciclosRef().doc(idCiclo);

    // LÓGICA DOBLADA SEGÚN EL TIPO DE CULTIVO
    if (ciclo.esCultivoContinuo) {
      // ───────────────────────────────────────────
      // LÓGICA DE COSECHA DE COHORTE (BANANO)
      // ───────────────────────────────────────────
      if (idEncintado == null) {
        throw const ValidationFailure(
          'Debe seleccionar qué cinta cosechar para cultivos continuos.',
        );
      }

      final indexEncintado = ciclo.encintados.indexWhere(
        (e) => e.id == idEncintado,
      );
      if (indexEncintado == -1) {
        throw const NotFoundFailure(
          'La cinta seleccionada no existe en este ciclo.',
        );
      }

      final encintado = ciclo.encintados[indexEncintado];
      final maxAllowed =
          encintado.disponible; // Assuming this is the correct variable
      if (cantidad > maxAllowed) {
        throw Exception(
          'La cantidad a cosechar no puede exceder la disponibilidad de esta cinta.',
        );
      }

      // Actualizar la cohorte específica
      final updatedEncintado = DetalleEncintado(
        id: encintado.id,
        cintaId: encintado.cintaId,
        cintaNombre: encintado.cintaNombre,
        cintaColorHex: encintado.cintaColorHex,
        cantidad: encintado.cantidad,
        cantidadCosechada: encintado.cantidadCosechada + cantidad,
        fecha: encintado.fecha,
        usuarioId: encintado.usuarioId,
      );

      final newList = List<DetalleEncintado>.from(ciclo.encintados);
      newList[indexEncintado] = updatedEncintado;

      batch.update(cicloRef, {
        'encintados': newList.map((e) => e.toMap()).toList(),
        'fecha_actualizacion': FieldValue.serverTimestamp(),
        // No cerramos el ciclo, no actualizamos mermas globales (eso se calculará por cohorte luego)
      });

      await batch.commit();

      return CicloProduccionModel(
        id: ciclo.id,
        idLote: ciclo.idLote,
        nombreLote: ciclo.nombreLote,
        idProductora: productoraId,
        estado: ciclo.estado, // Mantiene Sembrado o Encintado
        fechaSiembra: ciclo.fechaSiembra,
        area: ciclo.area,
        variedad: ciclo.variedad,
        esCultivoContinuo: ciclo.esCultivoContinuo,
        encintados: newList, // Update memory list
      );
    } else {
      // ───────────────────────────────────────────
      // LÓGICA DE COSECHA GLOBAL (MAÍZ, ESTACIONAL)
      // ───────────────────────────────────────────
      final cantidadEncintadoTotal = ciclo.totalEncintado;
      final merma = cantidadEncintadoTotal - cantidad;
      final mermaPorcentaje = cantidadEncintadoTotal > 0
          ? (merma / cantidadEncintadoTotal) * 100
          : 0.0;

      batch.update(cicloRef, {
        'estado': EstadoCiclo.cosechado.name,
        'cantidad_cosecha': cantidad,
        'merma': merma,
        'merma_porcentaje': mermaPorcentaje,
        'id_empacadora': idEmpacadora,
        'fecha_cosecha': Timestamp.fromDate(now),
        'fecha_actualizacion': FieldValue.serverTimestamp(),
      });

      // Liberar lote solo si NO es cultivo continuo
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
        esCultivoContinuo: ciclo.esCultivoContinuo,
        encintados: ciclo.encintados,
        cantidadCosecha: cantidad,
        merma: merma,
        mermaPorcentaje: mermaPorcentaje,
        idEmpacadora: idEmpacadora,
        uidRegistradoPor: uidUsuario,
        fechaCosecha: now,
      );
    }
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

      // Volumen En Cinta (Stock Activo): Solo lo que está ACTUALMENTE madurando en el campo.
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
