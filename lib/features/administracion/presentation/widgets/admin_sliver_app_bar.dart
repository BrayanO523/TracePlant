import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class AdminSliverAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AdminSliverAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 170.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20), // Compensar status bar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
