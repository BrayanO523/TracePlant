import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/role_constants.dart';
import '../viewmodels/users_notifier.dart';
import 'user_form_screen.dart';

class UsersScreen extends ConsumerWidget {
  final String companyId;
  final UserRole companyRole;

  const UsersScreen({
    super.key,
    required this.companyId,
    required this.companyRole,
  });

  UsersProviderKey get _key => (companyId: companyId, companyRole: companyRole);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersNotifierProvider(_key));

    // Escuchar mensajes
    ref.listen<UsersState>(usersNotifierProvider(_key), (
      UsersState? prev,
      UsersState next,
    ) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.estadoCosechado,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(usersNotifierProvider(_key).notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(usersNotifierProvider(_key).notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Usuarios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserFormScreen(
                companyId: companyId,
                companyRole: companyRole,
              ),
            ),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.employees.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay empleados registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca "Nuevo" para agregar un empleado.',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(usersNotifierProvider(_key).notifier).loadEmployees();
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: state.employees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = state.employees[index];
                  final isOwner = user.isOwner;

                  // Generar resumen de permisos
                  final permsLabels = <String>[];
                  final perms = user.effectivePermissions;
                  if (perms.tieneAdministracion) permsLabels.add('Admin');
                  if (perms.tieneProduccion) permsLabels.add('Producción');
                  if (perms.tieneConsultas) permsLabels.add('Consultas');
                  if (perms.tieneUsuarios) permsLabels.add('Usuarios');

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserFormScreen(
                              companyId: companyId,
                              companyRole: companyRole,
                              existingUser: user,
                            ),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isOwner
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          isOwner ? Icons.star_rounded : Icons.person_rounded,
                          color: isOwner ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName ?? user.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!user.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'INACTIVO',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Badge: Dueño o resumen de permisos
                          if (isOwner)
                            _RoleBadge(label: 'Dueño', color: AppColors.accent)
                          else if (permsLabels.isEmpty)
                            _RoleBadge(
                              label: 'Sin permisos',
                              color: AppColors.textHint,
                            )
                          else
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: permsLabels
                                  .map(
                                    (l) => _RoleBadge(
                                      label: l,
                                      color: AppColors.primary,
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                      trailing: isOwner
                          ? null
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textHint,
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
