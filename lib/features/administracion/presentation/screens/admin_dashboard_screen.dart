import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

import 'cintas_screen.dart';
import 'variedades_screen.dart';
import 'fincas_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Administración'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel de Admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gestiona catálogos de tu empresa',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _AdminCard(
            title: 'Colores de Cinta',
            subtitle: 'Definir códigos de colores y semanas de cosecha',
            icon: Icons.palette_rounded,
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CintasScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _AdminCard(
            title: 'Variedades',
            subtitle: 'Catálogo de variedades de producto',
            icon: Icons.local_florist_rounded,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VariedadesScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _AdminCard(
            title: 'Fincas y Lotes',
            subtitle: 'Gestionar fincas y sus lotes de producción',
            icon: Icons.landscape_rounded,
            color: AppColors.tertiary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FincasScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
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
                      title,
                      style: const TextStyle(
                        fontSize: 17,
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
