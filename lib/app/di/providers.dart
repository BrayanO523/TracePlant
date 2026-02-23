import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:productoraempacadora/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:productoraempacadora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:productoraempacadora/features/auth/domain/repositories/auth_repository.dart';
import 'package:productoraempacadora/features/auth/presentation/viewmodels/auth_notifier.dart';
import 'package:productoraempacadora/features/auth/domain/entities/app_user.dart';
import 'package:productoraempacadora/features/auth/data/models/user_model.dart';
import 'package:productoraempacadora/core/constants/firestore_paths.dart';

import 'package:productoraempacadora/features/produccion/data/datasources/produccion_remote_datasource.dart';
import 'package:productoraempacadora/features/produccion/data/repositories/produccion_repository_impl.dart';
import 'package:productoraempacadora/features/produccion/domain/repositories/produccion_repository.dart';
import 'package:productoraempacadora/features/produccion/presentation/viewmodels/lotes_notifier.dart';
import 'package:productoraempacadora/features/produccion/presentation/viewmodels/produccion_notifier.dart';

import 'package:productoraempacadora/features/administracion/domain/entities/finca.dart'; // Finca
import 'package:productoraempacadora/features/produccion/domain/entities/lote.dart'; // Lote
import 'package:productoraempacadora/features/produccion/domain/entities/ciclo_produccion.dart'; // CicloProduccion

// features/asignaciones
import 'package:productoraempacadora/features/asignaciones/data/datasources/asignaciones_remote_datasource.dart';
import 'package:productoraempacadora/features/asignaciones/data/repositories/asignaciones_repository_impl.dart';
import 'package:productoraempacadora/features/asignaciones/domain/repositories/asignaciones_repository.dart';
import 'package:productoraempacadora/features/asignaciones/presentation/viewmodels/asignaciones_notifier.dart';

// features/empacadora
import 'package:productoraempacadora/features/empacadora/data/datasources/empacadora_remote_datasource.dart';
import 'package:productoraempacadora/features/empacadora/data/repositories/empacadora_repository_impl.dart';
import 'package:productoraempacadora/features/empacadora/domain/repositories/empacadora_repository.dart';
import 'package:productoraempacadora/features/empacadora/presentation/viewmodels/empacadora_dashboard_notifier.dart';

import 'package:productoraempacadora/features/administracion/data/repositories/administracion_repository_impl.dart';
import 'package:productoraempacadora/features/administracion/domain/repositories/i_administracion_repository.dart';
import 'package:productoraempacadora/features/administracion/domain/entities/variedad.dart';
import 'package:productoraempacadora/features/administracion/domain/entities/cinta.dart';

// features/usuarios
import 'package:productoraempacadora/core/constants/role_constants.dart';
import 'package:productoraempacadora/features/usuarios/data/datasources/users_remote_datasource.dart';
import 'package:productoraempacadora/features/usuarios/data/repositories/users_repository_impl.dart';
import 'package:productoraempacadora/features/usuarios/domain/repositories/users_repository.dart';
import 'package:productoraempacadora/features/usuarios/presentation/viewmodels/users_notifier.dart';

// ═══════════════════════════════════════════════════════
//  CORE & EXTERNAL
// ═══════════════════════════════════════════════════════

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ═══════════════════════════════════════════════════════
//  AUTH FEATURE
// ═══════════════════════════════════════════════════════

final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasourceImpl(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authDatasourceProvider));
});

// AuthNotifier es un AsyncNotifier (void) para acciones de login/logout
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

// Stream simple de autenticación (Firebase User)
final authStateStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authDatasourceProvider).authStateChanges;
});

// Stream enriquecido con datos del usuario (AppUser con rol)
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateStreamProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }

      // Escuchar cambios en el documento del usuario en Firestore
      return ref
          .read(firestoreProvider)
          .collection(FirestorePaths.usuarios)
          .doc(user.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) {
              return null;
            }
            try {
              final entity = UserModel.fromDocument(doc).toEntity();
              return entity;
            } catch (e) {
              return null;
            }
          });
    },
    loading: () {
      return const Stream.empty();
    },
    error: (e, s) {
      return const Stream.empty();
    },
  );
});

// Stream para observar a un empleado en particular en tiempo real
final employeeStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  return ref
      .read(firestoreProvider)
      .collection(FirestorePaths.usuarios)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromDocument(doc) : null);
});

// ═══════════════════════════════════════════════════════
//  PRODUCCION FEATURE (Lotes y Ciclos)
// ═══════════════════════════════════════════════════════

final produccionDatasourceProvider = Provider<ProduccionRemoteDatasource>((
  ref,
) {
  return ProduccionRemoteDatasource(ref.read(firestoreProvider));
});

final produccionRepositoryProvider = Provider<ProduccionRepository>((ref) {
  return ProduccionRepositoryImpl(ref.read(produccionDatasourceProvider));
});

// Lotes Notifier (Family por Productora ID)
final lotesNotifierProvider =
    StateNotifierProvider.family<LotesNotifier, LotesState, String>((
      ref,
      productoraId,
    ) {
      return LotesNotifier(
        ref.read(produccionRepositoryProvider),
        productoraId,
      );
    });

// Produccion Notifier (Ciclos) (Family por Productora ID)
final produccionNotifierProvider =
    StateNotifierProvider.family<ProduccionNotifier, ProduccionState, String>((
      ref,
      productoraId,
    ) {
      return ProduccionNotifier(
        ref.read(produccionRepositoryProvider),
        productoraId,
      );
    });

final fincasStreamProviderFamily = StreamProvider.family<List<Finca>, String>((
  ref,
  productoraId,
) {
  return ref.watch(produccionRepositoryProvider).watchFincas(productoraId);
});

final lotesStreamProviderFamily = StreamProvider.family<List<Lote>, String>((
  ref,
  productoraId,
) {
  return ref.watch(produccionRepositoryProvider).watchLotes(productoraId);
});

final ciclosActivosStreamProviderFamily =
    StreamProvider.family<List<CicloProduccion>, String>((ref, productoraId) {
      return ref
          .watch(produccionRepositoryProvider)
          .watchCiclosActivos(productoraId);
    });

// ═══════════════════════════════════════════════════════
//  ADMINISTRACION FEATURE
// ═══════════════════════════════════════════════════════

final administracionRepositoryProvider = Provider<IAdministracionRepository>((
  ref,
) {
  return AdministracionRepositoryImpl(
    firestore: ref.read(firestoreProvider),
    auth: ref.read(firebaseAuthProvider),
  );
});

final variedadesStreamProvider = StreamProvider<List<Variedad>>((ref) {
  return ref.watch(administracionRepositoryProvider).watchVariedades();
});

final variedadesStreamProviderFamily =
    StreamProvider.family<List<Variedad>, String>((ref, productoraId) {
      return ref
          .watch(administracionRepositoryProvider)
          .watchVariedades(productoraId: productoraId);
    });

final cintasStreamProvider = StreamProvider<List<Cinta>>((ref) {
  return ref.watch(administracionRepositoryProvider).watchCintas();
});

final cintasStreamProviderFamily = StreamProvider.family<List<Cinta>, String>((
  ref,
  productoraId,
) {
  return ref
      .watch(administracionRepositoryProvider)
      .watchCintas(productoraId: productoraId);
});

// ═══════════════════════════════════════════════════════
//  ASIGNACIONES (Admin)
// ═══════════════════════════════════════════════════════

final asignacionesDatasourceProvider = Provider<AsignacionesRemoteDatasource>((
  ref,
) {
  return AsignacionesRemoteDatasource(ref.read(firestoreProvider));
});

final asignacionesRepositoryProvider = Provider<AsignacionesRepository>((ref) {
  return AsignacionesRepositoryImpl(ref.read(asignacionesDatasourceProvider));
});

final asignacionesNotifierProvider =
    StateNotifierProvider<AsignacionesNotifier, AsignacionesState>((ref) {
      return AsignacionesNotifier(ref.read(asignacionesRepositoryProvider));
    });

// ═══════════════════════════════════════════════════════
//  EMPACADORA (Dashboard View)
// ═══════════════════════════════════════════════════════

final empacadoraDatasourceProvider = Provider<EmpacadoraRemoteDatasource>((
  ref,
) {
  return EmpacadoraRemoteDatasource(ref.read(firestoreProvider));
});

final empacadoraRepositoryProvider = Provider<EmpacadoraRepository>((ref) {
  return EmpacadoraRepositoryImpl(ref.read(empacadoraDatasourceProvider));
});

/// Dashboard Notifier (Family por Empacadora ID)
final empacadoraDashboardProvider =
    StateNotifierProvider.family<
      EmpacadoraDashboardNotifier,
      EmpacadoraDashboardState,
      String
    >((ref, empacadoraId) {
      return EmpacadoraDashboardNotifier(
        ref.read(empacadoraRepositoryProvider),
        empacadoraId,
      );
    });

// ═══════════════════════════════════════════════════════
//  USUARIOS FEATURE
// ═══════════════════════════════════════════════════════

final usersDatasourceProvider = Provider<UsersRemoteDatasource>((ref) {
  return UsersRemoteDatasourceImpl(ref.read(firestoreProvider));
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepositoryImpl(ref.read(usersDatasourceProvider));
});

/// Typedef para el key del family provider
typedef UsersProviderKey = ({String companyId, UserRole companyRole});

final usersNotifierProvider =
    StateNotifierProvider.family<UsersNotifier, UsersState, UsersProviderKey>((
      ref,
      key,
    ) {
      return UsersNotifier(
        repository: ref.read(usersRepositoryProvider),
        companyId: key.companyId,
        companyRole: key.companyRole,
      );
    });
