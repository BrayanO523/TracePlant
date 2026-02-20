import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/user_permissions.dart';
import '../../../produccion/presentation/widgets/quick_actions_selector.dart';

/// Barra de acciones rápidas (Sembrar, Encintar, Cosechar).
/// Solo muestra los botones para los que el usuario tiene permiso de crear.
class QuickActionsBar extends ConsumerWidget {
  final String productoraId;
  final UserPermissions permissions;

  const QuickActionsBar({
    super.key,
    required this.productoraId,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Construir la lista de acciones según permisos
    final actions = <Widget>[];

    if (permissions.siembra.crear) {
      actions.add(
        _buildActionButton(
          context,
          icon: Icons.grass_rounded,
          label: 'Sembrar',
          color: AppColors.primary,
          onTap: () => QuickActionsSelector.showSiembraSelector(
            context,
            ref,
            productoraId,
          ),
        ),
      );
    }

    if (permissions.encintado.crear) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
      actions.add(
        _buildActionButton(
          context,
          icon: Icons.confirmation_number_rounded,
          label: 'Encintar',
          color: AppColors.secondary,
          onTap: () => QuickActionsSelector.showEncintadoSelector(
            context,
            ref,
            productoraId,
          ),
        ),
      );
    }

    if (permissions.cosecha.crear) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
      actions.add(
        _buildActionButton(
          context,
          icon: Icons.agriculture_rounded,
          label: 'Cosechar',
          color: AppColors.accent,
          onTap: () => QuickActionsSelector.showCosechaSelector(
            context,
            ref,
            productoraId,
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: actions),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
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
