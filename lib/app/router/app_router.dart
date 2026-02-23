import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../../../core/constants/role_constants.dart';
import '../../../features/auth/presentation/views/login_screen.dart';
import '../../../features/auth/presentation/views/register_screen.dart';
import '../../../features/auth/domain/entities/app_user.dart';
import '../../../features/asignaciones/presentation/views/admin_home_screen.dart';
import '../../../features/produccion/presentation/views/produccion_dashboard_screen.dart';
import '../../../features/produccion/presentation/consultas/views/consultas_screen.dart';
import '../../../features/empacadora/presentation/views/empacadora_home_screen.dart';

// Placeholders are defined at the bottom of this file

final goRouterProvider = Provider<GoRouter>((ref) {
  // Escuchar a Firestore (AppUser real) usando un Notifier para no reconstruir TODO el Router
  final authStateNotifier = ValueNotifier<AsyncValue<AppUser?>>(
    const AsyncLoading(),
  );

  ref.listen<AsyncValue<AppUser?>>(currentUserStreamProvider, (_, next) {
    authStateNotifier.value = next;
  }, fireImmediately: true);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final userState = authStateNotifier.value;
      final user = userState.asData?.value;
      final isLoggedIn = user != null;
      final isLoggingIn =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (userState.isLoading) return null; // Esperar a que cargue

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // If logged in and on login page, redirect to home
      if (isLoggingIn) {
        switch (user.role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.productora:
            return '/productora';
          case UserRole.empacadora:
            return '/empacadora';
        }
      }

      // Role-based guards
      if (state.uri.path.startsWith('/admin') && user.role != UserRole.admin) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/productora',
        builder: (context, state) {
          // Obtener productoraId del usuario logueado
          final user = authStateNotifier.value.asData?.value;
          final productoraId = user?.companyId ?? '';
          return ProduccionDashboardScreen(productoraId: productoraId);
        },
        routes: [
          GoRoute(
            path: 'consultas',
            builder: (context, state) {
              final user = authStateNotifier.value.asData?.value;
              final productoraId = user?.companyId ?? '';
              return ConsultasScreen(productoraId: productoraId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/empacadora',
        builder: (context, state) => const EmpacadoraHomeScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final user = authStateNotifier.value.asData?.value;
          if (user == null) return '/login';
          switch (user.role) {
            case UserRole.admin:
              return '/admin';
            case UserRole.productora:
              return '/productora';
            case UserRole.empacadora:
              return '/empacadora';
          }
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
