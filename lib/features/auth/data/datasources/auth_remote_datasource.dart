import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';
import '../../../productora/data/models/productora_model.dart';
import '../../../empacadora/data/models/empacadora_model.dart';

abstract class AuthRemoteDatasource {
  Stream<User?> get authStateChanges;
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> register({
    required String email,
    required String password,
    required UserRole role,
    required String companyName,
    required String location,
    required String rnt,
  });
  Future<void> signOut();
  Future<UserModel> getCurrentUser();
  Future<UserModel?> getUserProfile(String uid);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDatasourceImpl(this._auth, this._firestore);

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw const AuthFailure('Login failed: no user returned');
      }
      try {
        return await _getUserData(credential.user!.uid);
      } catch (e) {
        // AUTO-RECOVERY for dev accounts
        if (email == 'productora@gmail.com') {
          return await _recoverProfile(
            credential.user!.uid,
            email,
            UserRole.productora,
          );
        }
        if (email == 'empacadora@gmail.com') {
          return await _recoverProfile(
            credential.user!.uid,
            email,
            UserRole.empacadora,
          );
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Login failed');
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required UserRole role,
    required String companyName,
    required String location,
    required String rnt,
  }) async {
    try {
      // 1. Create Auth User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // 2. Prepare Batch
      final batch = _firestore.batch();

      // Auto-ID for company
      String companyCollection = role == UserRole.productora
          ? FirestorePaths.productoras
          : FirestorePaths.empacadoras;

      final companyRef = _firestore.collection(companyCollection).doc();
      final companyId = companyRef.id;

      // 3. Set Company Data
      if (role == UserRole.productora) {
        final productora = ProductoraModel(
          id: companyId,
          name: companyName,
          location: location,
          rnt: rnt,
          ownerUid: uid,
          createdAt: DateTime.now(),
          isActive: true,
        );
        batch.set(companyRef, productora.toJson());
      } else {
        final empacadora = EmpacadoraModel(
          id: companyId,
          name: companyName,
          location: location,
          rnt: rnt,
          ownerUid: uid,
          capacity: 0, // default
          createdAt: DateTime.now(),
          isActive: true,
          // shift y contactPhone opcionales, null por defecto
        );
        batch.set(companyRef, empacadora.toJson());
      }

      // 4. Set User Profile
      final userRef = _firestore.collection(FirestorePaths.usuarios).doc(uid);
      final userModel = UserModel(
        uid: uid,
        email: email,
        role: role,
        companyId: companyId,
        displayName: companyName,
        isActive: true,
      );

      batch.set(userRef, userModel.toJson());

      // 5. Commit
      await batch.commit();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Registration failed');
    } catch (e) {
      throw const ServerFailure('Registration failed');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<UserModel> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('No user logged in');
    return await _getUserData(user.uid);
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestorePaths.usuarios)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  Future<UserModel> _getUserData(String uid) async {
    final doc = await _firestore
        .collection(FirestorePaths.usuarios)
        .doc(uid)
        .get();
    if (!doc.exists) {
      // Fallback if auth exists but no profile (edge case)
      // For now throw error
      throw const NotFoundFailure('User profile not found');
    }
    return UserModel.fromDocument(doc);
  }

  Future<UserModel> _recoverProfile(
    String uid,
    String email,
    UserRole role,
  ) async {
    final batch = _firestore.batch();

    String companyCollection = role == UserRole.productora
        ? FirestorePaths.productoras
        : FirestorePaths.empacadoras;

    final companyRef = _firestore.collection(companyCollection).doc();
    final companyId = companyRef.id;
    final companyName = role == UserRole.productora
        ? "Productora Demo"
        : "Empacadora Demo";

    if (role == UserRole.productora) {
      final productora = ProductoraModel(
        id: companyId,
        name: companyName,
        location: "Ubicación Demo",
        rnt: "DEMO-RNT",
        ownerUid: uid,
        createdAt: DateTime.now(),
        isActive: true,
      );
      batch.set(companyRef, productora.toJson());
    } else {
      final empacadora = EmpacadoraModel(
        id: companyId,
        name: companyName,
        location: "Ubicación Demo",
        rnt: "DEMO-RNT",
        ownerUid: uid,
        capacity: 1000,
        createdAt: DateTime.now(),
        isActive: true,
      );
      batch.set(companyRef, empacadora.toJson());
    }

    final userRef = _firestore.collection(FirestorePaths.usuarios).doc(uid);
    final userModel = UserModel(
      uid: uid,
      email: email,
      role: role,
      companyId: companyId,
      displayName: companyName,
      isActive: true,
    );

    batch.set(userRef, userModel.toJson());

    await batch.commit();

    return userModel;
  }
}
