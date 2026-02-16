import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:productoraempacadora/core/constants/role_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/views/auth_gate.dart';
import '../../../administracion/presentation/screens/admin_dashboard_screen.dart';
import '../../../produccion/presentation/views/produccion_dashboard_screen.dart';
import '../../../produccion/presentation/consultas/views/consultas_screen.dart';
import '../../../productora/presentation/views/productora_settings_screen.dart';
import '../../../../app/di/providers.dart';
import '../widgets/quick_actions_bar.dart'; // Ruta corregida: subir un nivel desde screens/

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
                        100,
                      ), // Espacio extra abajo para quick actions
                      child: Column(
                        children: [
                          _MenuCard(
                            icon: Icons.admin_panel_settings_rounded,
                            label: 'Administración',
                            subtitle: 'Fincas, Lotes, Cintas, Variedades',
                            color: AppColors.info,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _MenuCard(
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
                                    builder: (_) => ProduccionDashboardScreen(
                                      productoraId: productoraId,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Error: No se encontró la empresa',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _MenuCard(
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Error: No se encontró la empresa',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Quick Actions Bar (Bottom Fixed) ---
          if (showQuickActions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuickActionsBar(productoraId: productoraId!),
            ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
