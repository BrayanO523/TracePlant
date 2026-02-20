import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/constants/user_permissions.dart';
import '../../../auth/data/models/user_model.dart';

/// Datasource remoto para gestión de empleados de una empresa.
///
/// IMPORTANTE: Para crear empleados sin cerrar la sesión del dueño,
/// usamos una segunda instancia de FirebaseAuth.
abstract class UsersRemoteDatasource {
  /// Crea un nuevo empleado: cuenta en Firebase Auth + perfil en Firestore.
  Future<UserModel> createEmployee({
    required String email,
    required String password,
    required String displayName,
    required UserPermissions permissions,
    required String companyId,
    required UserRole companyRole,
  });

  /// Lista todos los usuarios de una empresa (por id_empresa).
  Future<List<UserModel>> getEmployees(String companyId);

  /// Actualiza el perfil de un empleado (permisos, nombre, activo).
  Future<void> updateEmployee({
    required String uid,
    String? displayName,
    UserPermissions? permissions,
    bool? isActive,
  });

  /// Desactiva un empleado (soft-delete).
  Future<void> deactivateEmployee(String uid);
}

class UsersRemoteDatasourceImpl implements UsersRemoteDatasource {
  final FirebaseFirestore _firestore;

  UsersRemoteDatasourceImpl(this._firestore);

  @override
  Future<UserModel> createEmployee({
    required String email,
    required String password,
    required String displayName,
    required UserPermissions permissions,
    required String companyId,
    required UserRole companyRole,
  }) async {
    // Usar una segunda instancia de FirebaseAuth para no cerrar sesión del dueño
    final secondaryApp = Firebase.app('employeeCreator');
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      // 1. Crear cuenta en Firebase Auth (instancia secundaria)
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Cerrar sesión en la instancia secundaria inmediatamente
      await secondaryAuth.signOut();

      // 2. Crear perfil en Firestore con permisos granulares
      final userModel = UserModel(
        uid: uid,
        email: email,
        role: companyRole,
        companyId: companyId,
        displayName: displayName,
        isActive: true,
        isOwner: false,
        permissions: permissions,
      );

      await _firestore
          .collection(FirestorePaths.usuarios)
          .doc(uid)
          .set(userModel.toJson());

      return userModel;
    } catch (e) {
      // Limpiar la sesión secundaria en caso de error
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getEmployees(String companyId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.usuarios)
        .where('id_empresa', isEqualTo: companyId)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  }

  @override
  Future<void> updateEmployee({
    required String uid,
    String? displayName,
    UserPermissions? permissions,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['nombre'] = displayName;
    if (permissions != null) updates['permisos'] = permissions.toJson();
    if (isActive != null) updates['activo'] = isActive;

    if (updates.isNotEmpty) {
      await _firestore
          .collection(FirestorePaths.usuarios)
          .doc(uid)
          .update(updates);
    }
  }

  @override
  Future<void> deactivateEmployee(String uid) async {
    await _firestore.collection(FirestorePaths.usuarios).doc(uid).update({
      'activo': false,
    });
  }
}
