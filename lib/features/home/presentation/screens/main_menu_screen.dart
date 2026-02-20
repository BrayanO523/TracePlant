import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/views/auth_gate.dart';
import '../../../administracion/presentation/screens/admin_dashboard_screen.dart';
import '../../../produccion/presentation/views/produccion_dashboard_screen.dart';
import '../../../produccion/presentation/consultas/views/consultas_screen.dart';
import '../../../productora/presentation/views/productora_settings_screen.dart';
import '../../../usuarios/presentation/views/users_screen.dart';
import '../../../../app/di/providers.dart';
import '../../../../core/constants/role_constants.dart';
import '../widgets/quick_actions_bar.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el usuario para obtener ID de productora
    final userAsync = ref.watch(currentUserStreamProvider);
    final appUser = userAsync.value;
    final productoraId = appUser?.companyId;

    // Validar si podemos mostrar acciones rápidas (solo si tiene companyId y rol productora)
    final showQuickActions =
        productoraId != null &&
        productoraId.isNotEmpty &&
        appUser?.role == UserRole.productora;

    // Permisos efectivos del usuario
    final perms = appUser?.effectivePermissions;

    return Scaffold(
      backgroundColor: AppColors.surface, // Fondo base
      body: Stack(
        children: [
          // Fondo gradiente superior
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // --- Header ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TracePlant',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Menú Principal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (appUser
                                  ?.effectivePermissions
                                  .ajustesEmpresa
                                  .ver ==
                              true)
                            IconButton(
                              icon: const Icon(
                                Icons.settings_rounded,
                                color: Colors.white70,
                              ),
                              tooltip: 'Ajustes',
                              onPressed: () {
                                if (productoraId != null &&
                                    productoraId.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductoraSettingsScreen(
                                        productoraId: productoraId,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sin empresa asignada'),
                                    ),
                                  );
                                }
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white70,
                            ),
                            tooltip: 'Salir',
                            onPressed: () async {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const AuthGate(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- Menu Cards (Scrollable) ---
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    clipBehavior: Clip
                        .antiAlias, // Para que el scroll no se salga de las esquinas redondeadas
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        30,
                        20,
                        200,
                      ), // Espacio extra abajo para quick actions
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double width = constraints.maxWidth;
                          // 2 columnas por defecto en teléfonos, 3 en tablets
                          final int columns = width > 600 ? 3 : 2;
                          final double spacing = 12.0;
                          final double itemWidth =
                              (width - ((columns - 1) * spacing)) / columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              // Administración: visible si tiene permiso en al menos un sub-módulo
                              if (perms != null && perms.tieneAdministracion)
                                _MenuCard(
                                  width: itemWidth,
                                  icon: Icons.admin_panel_settings_rounded,
                                  label: 'Administración',
                                  subtitle: 'Fincas, Lotes, Cintas, Variedades',
                                  color: AppColors.info,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminDashboardScreen(),
                                      ),
                                    );
                                  },
                                ),
                              // Producción: visible si tiene permiso en al menos un sub-módulo
                              if (perms != null && perms.tieneProduccion)
                                _MenuCard(
                                  width: itemWidth,
                                  icon: Icons.eco_rounded,
                                  label: 'Producción',
                                  subtitle: 'Siembra, Encintado, Cosecha',
                                  color: AppColors.primary,
                                  onTap: () {
                                    if (productoraId != null &&
                                        productoraId.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProduccionDashboardScreen(
                                                productoraId: productoraId,
                                              ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Error: No se encontró la empresa',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              // Consultas: visible si tiene permiso
                              if (perms != null && perms.tieneConsultas)
                                _MenuCard(
                                  width: itemWidth,
                                  icon: Icons.analytics_rounded,
                                  label: 'Consultas',
                                  subtitle: 'Historial y filtros avanzados',
                                  color: AppColors.secondary,
                                  onTap: () {
                                    if (productoraId != null &&
                                        productoraId.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ConsultasScreen(
                                            productoraId: productoraId,
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Error: No se encontró la empresa',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              // Usuarios: visible si tiene permiso
                              if (perms != null && perms.tieneUsuarios)
                                _MenuCard(
                                  width: itemWidth,
                                  icon: Icons.people_rounded,
                                  label: 'Usuarios',
                                  subtitle: 'Gestionar empleados y permisos',
                                  color: AppColors.accent,
                                  onTap: () {
                                    if (productoraId != null &&
                                        productoraId.isNotEmpty &&
                                        appUser != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UsersScreen(
                                            companyId: productoraId,
                                            companyRole: appUser.role,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Quick Actions Bar (Bottom Fixed) ---
          if (showQuickActions && perms != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuickActionsBar(
                productoraId: productoraId,
                permissions: perms,
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _MenuCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
