import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/cinta.dart';
import '../../domain/entities/finca.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/variedad.dart';
import '../../domain/repositories/i_administracion_repository.dart';
import '../models/cinta_model.dart';
import '../models/finca_model.dart';
import '../models/lote_model.dart';
import '../models/variedad_model.dart';

class AdministracionRepositoryImpl implements IAdministracionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Cache del companyId (productoraId) del usuario actual.
  String? _cachedProducerId;
  String? _cachedUid;

  AdministracionRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Resuelve el companyId (id_empresa) del usuario desde su perfil Firestore.
  Future<String> _getProducerId() async {
    final uid = _currentUserId;
    if (uid.isEmpty) return '';

    if (_cachedProducerId != null &&
        _cachedProducerId!.isNotEmpty &&
        _cachedUid == uid) {
      return _cachedProducerId!;
    }

    // 1. Obtener datos del usuario
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    final data = doc.data();

    // 2. Obtener id_empresa actual (puede ser el UID incorrecto)
    String empresaId = (data?['id_empresa'] as String?) ?? '';

    // 3. Auto-Corrección:
    // Si no tiene empresaId o si es igual al UID (lo cual el usuario indicó incorrecto),
    // buscamos si este usuario es DUEÑO de una productora en la colección 'productoras'.
    if (empresaId.isEmpty || empresaId == uid) {
      try {
        final query = await _firestore
            .collection('productoras')
            .where('ownerUid', isEqualTo: uid)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final foundId = query.docs.first.id;
          if (foundId != empresaId) {
            empresaId = foundId;

            // Opcional: Persistir la corrección en el usuario para futuras sesiones
            // await _firestore.collection('usuarios').doc(uid).update({'id_empresa': foundId});
          }
        }
      } catch (e) {
        // Ignored
      }
    }

    _cachedProducerId = empresaId;
    _cachedUid = uid;
    return _cachedProducerId!;
  }

  // --- Cintas ---
  @override
  Future<void> saveCinta(Cinta cinta) async {
    final producerId = await _getProducerId();

    final collection = _firestore.collection('cintas');
    final docRef = cinta.id.isEmpty
        ? collection.doc()
        : collection.doc(cinta.id);

    final model = CintaModel(
      id: docRef.id,
      color: cinta.color,
      descripcion: cinta.descripcion,
      colorHex: cinta.colorHex,
      productoraId: producerId,
    );

    await docRef.set(model.toFirestore());
  }

  @override
  Stream<List<Cinta>> watchCintas({String? productoraId}) {
    final streamId = productoraId != null
        ? Stream.value(productoraId)
        : Stream.fromFuture(_getProducerId());

    return streamId.asyncExpand((pid) {
      if (pid.isEmpty) return Stream.value([]);
      return _firestore
          .collection('cintas')
          .where('productoraId', isEqualTo: pid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => CintaModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  @override
  Future<void> deleteCinta(String id) async {
    await _firestore.collection('cintas').doc(id).delete();
  }

  // --- Variedades ---
  @override
  Future<void> saveVariedad(Variedad variedad) async {
    final producerId = await _getProducerId();
    final collection = _firestore.collection('variedades');
    final docRef = variedad.id.isEmpty
        ? collection.doc()
        : collection.doc(variedad.id);
    final model = VariedadModel(
      id: docRef.id,
      nombre: variedad.nombre,
      descripcion: variedad.descripcion,
      productoraId: producerId,
      esCultivoContinuo: variedad.esCultivoContinuo,
    );
    await docRef.set(model.toFirestore());
  }

  @override
  Stream<List<Variedad>> watchVariedades({String? productoraId}) {
    final streamId = productoraId != null
        ? Stream.value(productoraId)
        : Stream.fromFuture(_getProducerId());

    return streamId.asyncExpand((pid) {
      if (pid.isEmpty) return Stream.value([]);
      return _firestore
          .collection('variedades')
          .where('productoraId', isEqualTo: pid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => VariedadModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  @override
  Future<void> deleteVariedad(String id) async {
    await _firestore.collection('variedades').doc(id).delete();
  }

  // --- Fincas ---
  @override
  Future<void> saveFinca(Finca finca) async {
    final producerId = await _getProducerId();
    final collection = _firestore.collection('fincas');
    final docRef = finca.id.isEmpty
        ? collection.doc()
        : collection.doc(finca.id);
    final model = FincaModel(
      id: docRef.id,
      nombre: finca.nombre,
      ubicacion: finca.ubicacion,
      areaTotal: finca.areaTotal,
      productoraId: producerId,
      activo: finca.activo,
      coordenadas: finca.coordenadas,
    );
    await docRef.set(model.toFirestore());
  }

  @override
  Stream<List<Finca>> watchFincas() {
    return Stream.fromFuture(_getProducerId()).asyncExpand((producerId) {
      return _firestore
          .collection('fincas')
          .where('productoraId', isEqualTo: producerId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FincaModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  @override
  Future<Finca?> getFincaById(String id) async {
    final doc = await _firestore.collection('fincas').doc(id).get();
    if (doc.exists) {
      return FincaModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<void> deleteFinca(String id) async {
    // Implementación de borrado en cascada: Finca -> Lotes -> Ciclos
    final batch = _firestore.batch();

    // 1. Obtener Lotes de la Finca
    final lotesSnap = await _firestore
        .collection('lotes')
        .where('fincaId', isEqualTo: id)
        .get();

    for (var loteDoc in lotesSnap.docs) {
      // 2. Para cada lote, obtener sus Ciclos de Producción
      final ciclosSnap = await _firestore
          .collection('ciclos_produccion')
          .where('id_lote', isEqualTo: loteDoc.id)
          .get();

      // 3. Eliminar Ciclos
      for (var cicloDoc in ciclosSnap.docs) {
        batch.delete(cicloDoc.reference);
      }

      // 4. Eliminar Lote
      batch.delete(loteDoc.reference);
    }

    // 5. Eliminar la Finca
    batch.delete(_firestore.collection('fincas').doc(id));

    await batch.commit();
  }

  // --- Lotes ---
  @override
  Future<void> saveLote(Lote lote) async {
    final producerId = await _getProducerId();
    final collection = _firestore.collection('lotes');
    final isNew = lote.id.isEmpty;
    final docRef = isNew ? collection.doc() : collection.doc(lote.id);

    final model = LoteModel(
      id: docRef.id,
      nombre: lote.nombre,
      area: lote.area,
      fincaId: lote.fincaId,
      variedadId: lote.variedadId,
      variedadNombre: lote.variedadNombre,
      productoraId: producerId,
      estado: lote.estado,
      coordenadas: lote.coordenadas,
    );

    if (isNew) {
      await docRef.set(model.toFirestore());
    } else {
      // Merge para no borrar campos que no se envían en este save
      await docRef.set(model.toFirestore(), SetOptions(merge: true));
    }
  }

  @override
  Stream<List<Lote>> watchLotesByFinca(String fincaId) {
    return Stream.fromFuture(_getProducerId()).asyncExpand((producerId) {
      return _firestore
          .collection('lotes')
          .where('productoraId', isEqualTo: producerId)
          .where('fincaId', isEqualTo: fincaId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => LoteModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  @override
  Future<List<Lote>> getLotesByFincaFuture(String fincaId) async {
    final producerId = await _getProducerId();
    final snapshot = await _firestore
        .collection('lotes')
        .where('productoraId', isEqualTo: producerId)
        .where('fincaId', isEqualTo: fincaId)
        .get();
    return snapshot.docs.map((doc) => LoteModel.fromFirestore(doc)).toList();
  }

  @override
  Stream<List<Lote>> watchAllLotes() {
    return Stream.fromFuture(_getProducerId()).asyncExpand((producerId) {
      return _firestore
          .collection('lotes')
          .where('productoraId', isEqualTo: producerId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => LoteModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  @override
  Future<void> deleteLote(String id) async {
    // Implementación de borrado en cascada: Lote -> Ciclos
    final batch = _firestore.batch();

    // 1. Obtener Ciclos del Lote
    final ciclosSnap = await _firestore
        .collection('ciclos_produccion')
        .where('id_lote', isEqualTo: id)
        .get();

    // 2. Eliminar Ciclos
    for (var cicloDoc in ciclosSnap.docs) {
      batch.delete(cicloDoc.reference);
    }

    // 3. Eliminar Lote
    batch.delete(_firestore.collection('lotes').doc(id));

    await batch.commit();
  }
}
