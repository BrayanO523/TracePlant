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

  AdministracionRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  // --- Cintas ---
  @override
  Future<void> saveCinta(Cinta cinta) async {
    final collection = _firestore.collection('cintas');
    final docRef = cinta.id.isEmpty
        ? collection.doc()
        : collection.doc(cinta.id);

    final model = CintaModel(
      id: docRef.id,
      color: cinta.color,
      descripcion: cinta.descripcion,
      colorHex: cinta.colorHex,
      productoraId: cinta.productoraId,
    );

    await docRef.set(model.toFirestore());
  }

  @override
  Stream<List<Cinta>> watchCintas() {
    return _firestore
        .collection('cintas')
        .where('productoraId', isEqualTo: _currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CintaModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> deleteCinta(String id) async {
    await _firestore.collection('cintas').doc(id).delete();
  }

  // --- Variedades ---
  @override
  Future<void> saveVariedad(Variedad variedad) async {
    final collection = _firestore.collection('variedades');
    final docRef = variedad.id.isEmpty
        ? collection.doc()
        : collection.doc(variedad.id);

    final model = VariedadModel(
      id: docRef.id,
      nombre: variedad.nombre,
      descripcion: variedad.descripcion,
      productoraId: variedad.productoraId,
    );
    await docRef.set(model.toFirestore());
  }

  @override
  Stream<List<Variedad>> watchVariedades() {
    return _firestore
        .collection('variedades')
        .where('productoraId', isEqualTo: _currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VariedadModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> deleteVariedad(String id) async {
    await _firestore.collection('variedades').doc(id).delete();
  }

  // --- Fincas ---
  @override
  Future<void> saveFinca(Finca finca) async {
    final collection = _firestore.collection('fincas');
    final docRef = finca.id.isEmpty
        ? collection.doc()
        : collection.doc(finca.id);

    final model = FincaModel(
      id: docRef.id,
      nombre: finca.nombre,
      ubicacion: finca.ubicacion,
      areaTotal: finca.areaTotal,
      productoraId: finca.productoraId,
      activo: finca.activo,
    );
    await docRef.set(model.toFirestore());
  }

  @override
  Stream<List<Finca>> watchFincas() {
    return _firestore
        .collection('fincas')
        .where('productoraId', isEqualTo: _currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FincaModel.fromFirestore(doc))
              .toList(),
        );
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
    await _firestore.collection('fincas').doc(id).delete();
  }

  // --- Lotes ---
  @override
  Future<void> saveLote(Lote lote) async {
    final collection = _firestore.collection('lotes');
    final docRef = lote.id.isEmpty ? collection.doc() : collection.doc(lote.id);

    final model = LoteModel(
      id: docRef.id,
      nombre: lote.nombre,
      area: lote.area,
      fincaId: lote.fincaId,
      variedadId: lote.variedadId,
      productoraId: lote.productoraId,
      estado: lote.estado,
    );
    await docRef.set(model.toFirestore());
  }

  @override
  Stream<List<Lote>> watchLotesByFinca(String fincaId) {
    return _firestore
        .collection('lotes')
        .where('productoraId', isEqualTo: _currentUserId)
        .where('fincaId', isEqualTo: fincaId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => LoteModel.fromFirestore(doc)).toList(),
        );
  }

  @override
  Future<List<Lote>> getLotesByFincaFuture(String fincaId) async {
    final snapshot = await _firestore
        .collection('lotes')
        .where('productoraId', isEqualTo: _currentUserId)
        .where('fincaId', isEqualTo: fincaId)
        .get();
    return snapshot.docs.map((doc) => LoteModel.fromFirestore(doc)).toList();
  }

  @override
  Stream<List<Lote>> watchAllLotes() {
    return _firestore
        .collection('lotes')
        .where('productoraId', isEqualTo: _currentUserId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => LoteModel.fromFirestore(doc)).toList(),
        );
  }

  @override
  Future<void> deleteLote(String id) async {
    await _firestore.collection('lotes').doc(id).delete();
  }
}
