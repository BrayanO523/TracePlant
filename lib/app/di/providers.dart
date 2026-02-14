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

final cintasStreamProvider = StreamProvider<List<Cinta>>((ref) {
  return ref.watch(administracionRepositoryProvider).watchCintas();
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
