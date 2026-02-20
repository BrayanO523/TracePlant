import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../asignaciones/presentation/views/admin_home_screen.dart';
import '../../../empacadora/presentation/views/empacadora_home_screen.dart';
import '../../../home/presentation/screens/main_menu_screen.dart';
import 'login_screen.dart';

/// Widget que verifica el estado de autenticación y enruta
/// a la pantalla correcta según el rol del usuario.
///
/// - No autenticado → LoginScreen
/// - admin → AdminHomeScreen
/// - productora → MainMenuScreen
/// - empacadora → EmpacadoraHomeScreen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Verificar si hay sesión de Firebase Auth
    final authState = ref.watch(authStateStreamProvider);

    return authState.when(
      loading: () => const _SplashLoading(),
      error: (e, _) => const LoginScreen(),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          // No hay sesión → Login
          return const LoginScreen();
        }

        // 2. Hay sesión → obtener perfil enriquecido (AppUser con rol)
        final userProfile = ref.watch(currentUserStreamProvider);

        return userProfile.when(
          loading: () => const _SplashLoading(),
          error: (e, _) {
            // Error cargando perfil → mostrar login con mensaje
            return const LoginScreen();
          },
          data: (appUser) {
            if (appUser == null) {
              // Usuario autenticado pero sin perfil en Firestore
              return const _ProfileErrorScreen();
            }

            if (!appUser.isActive) {
              return const _InactiveAccountScreen();
            }

            // 3. Enrutar según rol
            return switch (appUser.role) {
              UserRole.admin => const AdminHomeScreen(),
              UserRole.productora => const MainMenuScreen(),
              UserRole.empacadora => const EmpacadoraHomeScreen(),
            };
          },
        );
      },
    );
  }
}

/// Pantalla de carga mientras se verifica el estado de auth.
class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_rounded, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'TracePlant',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla de error cuando el usuario tiene sesión pero no perfil en Firestore.
class _ProfileErrorScreen extends ConsumerWidget {
  const _ProfileErrorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Perfil no encontrado',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu cuenta no tiene un perfil de usuario registrado '
                  'en el sistema. Contacta al administrador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar Sesión'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla de error cuando la cuenta está desactivada por el administrador.
class _InactiveAccountScreen extends ConsumerWidget {
  const _InactiveAccountScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Cuenta Desactivada',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El administrador ha desactivado tu acceso al sistema.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Volver al Login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
