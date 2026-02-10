import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../../productora/data/models/productora_model.dart';
import '../../../empacadora/data/models/empacadora_model.dart';
import '../../domain/entities/asignacion_enums.dart';
import '../models/asignacion_model.dart';

/// Datasource remoto para operaciones de asignación en Firestore.
///
/// Contiene TODAS las validaciones de integridad de datos:
/// - Empresa existe y está activa
/// - Productora no asignada a otra empacadora
/// - Relación 1:N (una productora → una sola empacadora activa)
class AsignacionesRemoteDatasource {
  final FirebaseFirestore _firestore;

  AsignacionesRemoteDatasource(this._firestore);

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════

  CollectionReference get _asignacionesRef =>
      _firestore.collection(FirestorePaths.asignaciones);

  CollectionReference get _productorasRef =>
      _firestore.collection(FirestorePaths.productoras);

  CollectionReference get _empacadorasRef =>
      _firestore.collection(FirestorePaths.empacadoras);

  // ═══════════════════════════════════════════════════════
  //  STREAMS
  // ═══════════════════════════════════════════════════════

  /// Stream reactivo de asignaciones activas, ordenadas por fecha.
  Stream<List<AsignacionModel>> watchAsignacionesActivas() {
    return _asignacionesRef
        .where('estado', isEqualTo: EstadoAsignacion.activa.name)
        .orderBy('fecha_asignacion', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AsignacionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ═══════════════════════════════════════════════════════
  //  QUERIES
  // ═══════════════════════════════════════════════════════

  /// Retorna productoras activas que NO tienen asignación activa.
  ///
  /// Estrategia: obtener todas las productoras activas, luego excluir
  /// las que ya tienen asignación activa. Se hace client-side porque
  /// Firestore no soporta NOT IN con otra colección.
  Future<List<ProductoraModel>> getProductorasDisponibles() async {
    // 1. IDs de productoras ya asignadas
    final asignacionesSnap = await _asignacionesRef
        .where('estado', isEqualTo: EstadoAsignacion.activa.name)
        .get();

    final idsAsignadas = asignacionesSnap.docs
        .map(
          (doc) =>
              (doc.data() as Map<String, dynamic>)['id_productora'] as String,
        )
        .toSet();

    // 2. Todas las productoras activas
    final productorasSnap = await _productorasRef
        .where('activo', isEqualTo: true)
        .get();

    // 3. Filtrar: solo las que NO están en idsAsignadas
    return productorasSnap.docs
        .map((doc) => ProductoraModel.fromFirestore(doc))
        .where((p) => !idsAsignadas.contains(p.id))
        .toList();
  }

  /// Retorna todas las empacadoras activas.
  Future<List<EmpacadoraModel>> getEmpacadorasActivas() async {
    final snap = await _empacadorasRef.where('activo', isEqualTo: true).get();

    return snap.docs.map((doc) => EmpacadoraModel.fromFirestore(doc)).toList();
  }

  /// Mapa de carga: empacadoraId → cantidad de productoras asignadas.
  Future<Map<String, int>> getCargaTrabajo() async {
    final snap = await _asignacionesRef
        .where('estado', isEqualTo: EstadoAsignacion.activa.name)
        .get();

    final carga = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final idEmp = data['id_empacadora'] as String;
      carga[idEmp] = (carga[idEmp] ?? 0) + 1;
    }
    return carga;
  }

  // ═══════════════════════════════════════════════════════
  //  MUTACIONES
  // ═══════════════════════════════════════════════════════

  /// Crea una asignación individual con validaciones completas.
  ///
  /// Validaciones:
  /// 1. La empacadora existe y está activa
  /// 2. La productora existe y está activa
  /// 3. La productora NO tiene otra asignación activa (relación 1:N)
  Future<void> crearAsignacion({
    required String idEmpacadora,
    required String idProductora,
  }) async {
    // ── Validación 1: Empacadora existe y activa ──
    final empDoc = await _empacadorasRef.doc(idEmpacadora).get();
    if (!empDoc.exists) {
      throw const NotFoundFailure('La empacadora no existe');
    }
    final empData = empDoc.data() as Map<String, dynamic>;
    if (empData['activo'] != true) {
      throw const ValidationFailure('La empacadora no está activa');
    }

    // ── Validación 2: Productora existe y activa ──
    final prodDoc = await _productorasRef.doc(idProductora).get();
    if (!prodDoc.exists) {
      throw const NotFoundFailure('La productora no existe');
    }
    final prodData = prodDoc.data() as Map<String, dynamic>;
    if (prodData['activo'] != true) {
      throw const ValidationFailure('La productora no está activa');
    }

    // ── Validación 3: Productora no asignada actualmente ──
    final existente = await _asignacionesRef
        .where('id_productora', isEqualTo: idProductora)
        .where('estado', isEqualTo: EstadoAsignacion.activa.name)
        .limit(1)
        .get();

    if (existente.docs.isNotEmpty) {
      throw const ValidationFailure(
        'Esta productora ya está asignada a otra empacadora',
      );
    }

    // ── Crear asignación ──
    final docRef = _asignacionesRef.doc();
    final asignacion = AsignacionModel(
      id: docRef.id,
      idEmpacadora: idEmpacadora,
      idProductora: idProductora,
      nombreEmpacadora: empData['nombre'] ?? '',
      nombreProductora: prodData['nombre'] ?? '',
      estado: EstadoAsignacion.activa,
      fechaAsignacion: DateTime.now(),
    );

    await docRef.set(asignacion.toJsonCreate());
  }

  /// Crea múltiples asignaciones en un solo batch.
  /// Valida cada productora individualmente antes de crear.
  Future<void> crearAsignacionesBatch({
    required String idEmpacadora,
    required List<String> idsProductoras,
  }) async {
    if (idsProductoras.isEmpty) {
      throw const ValidationFailure('Seleccione al menos una productora');
    }

    // Validar empacadora una sola vez
    final empDoc = await _empacadorasRef.doc(idEmpacadora).get();
    if (!empDoc.exists) {
      throw const NotFoundFailure('La empacadora no existe');
    }
    final empData = empDoc.data() as Map<String, dynamic>;
    if (empData['activo'] != true) {
      throw const ValidationFailure('La empacadora no está activa');
    }
    final nombreEmpacadora = empData['nombre'] as String? ?? '';

    // Obtener IDs ya asignadas para validación rápida
    final asignacionesSnap = await _asignacionesRef
        .where('estado', isEqualTo: EstadoAsignacion.activa.name)
        .get();
    final idsYaAsignadas = asignacionesSnap.docs
        .map(
          (d) => (d.data() as Map<String, dynamic>)['id_productora'] as String,
        )
        .toSet();

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final idProd in idsProductoras) {
      // Validar que no esté ya asignada
      if (idsYaAsignadas.contains(idProd)) continue;

      // Validar productora
      final prodDoc = await _productorasRef.doc(idProd).get();
      if (!prodDoc.exists) continue;
      final prodData = prodDoc.data() as Map<String, dynamic>;
      if (prodData['activo'] != true) continue;

      final docRef = _asignacionesRef.doc();
      final asignacion = AsignacionModel(
        id: docRef.id,
        idEmpacadora: idEmpacadora,
        idProductora: idProd,
        nombreEmpacadora: nombreEmpacadora,
        nombreProductora: prodData['nombre'] ?? '',
        estado: EstadoAsignacion.activa,
        fechaAsignacion: now,
      );
      batch.set(docRef, asignacion.toJsonCreate());
    }

    await batch.commit();
  }

  /// Finaliza una asignación, liberando la productora.
  Future<void> finalizarAsignacion(String idAsignacion) async {
    final docRef = _asignacionesRef.doc(idAsignacion);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw const NotFoundFailure('Asignación no encontrada');
    }

    await docRef.update({
      'estado': EstadoAsignacion.finalizada.name,
      'fecha_finalizacion': FieldValue.serverTimestamp(),
    });
  }
}
