import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/constants/user_permissions.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Formulario para crear o editar un empleado.
/// Si [existingUser] es null → modo creación.
/// Si [existingUser] no es null → modo edición.
class UserFormScreen extends ConsumerStatefulWidget {
  final String companyId;
  final UserRole companyRole;
  final AppUser? existingUser;
  final bool readOnly;

  const UserFormScreen({
    super.key,
    required this.companyId,
    required this.companyRole,
    this.existingUser,
    this.readOnly = false,
  });

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  late UserPermissions _permissions;

  bool get _isEditing => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final user = widget.existingUser!;
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email;
      _permissions = user.permissions;
    } else {
      _permissions = const UserPermissions.none();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      ref.listen<AsyncValue<UserModel?>>(
        employeeStreamProvider(widget.existingUser!.uid),
        (previous, next) {
          if (next.hasValue && next.value != null) {
            final remotePerms = next.value!.permissions;
            if (remotePerms != _permissions) {
              setState(() {
                _permissions = remotePerms;
              });
            }
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Empleado' : 'Nuevo Empleado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Info Card ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Puedes cambiar el nombre y los permisos. '
                                  'El correo no se puede modificar aquí.'
                            : 'Configura los permisos del empleado. '
                                  'Solo verá las secciones habilitadas.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Nombre ---
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                readOnly: widget.readOnly,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // --- Email ---
              if (!_isEditing)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),

              if (_isEditing)
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),

              const SizedBox(height: 16),

              // --- Contraseña (solo creación) ---
              if (!_isEditing) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Mínimo 6 caracteres',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // ══════════════════════════════════════════
              //  SECCIÓN DE PERMISOS
              // ══════════════════════════════════════════

              // Solo mostrar permisos si no es owner
              if (!(_isEditing && widget.existingUser!.isOwner)) ...[
                const Text(
                  'Permisos del Empleado',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Activa las secciones y acciones permitidas.',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 16),

                // ── ADMINISTRACIÓN ──
                _PermissionModule(
                  title: 'Administración',
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppColors.accent,
                  children: [
                    _PermissionSubModule(
                      title: 'Colores de Cinta',
                      icon: Icons.palette_rounded,
                      permission: _permissions.cintas,
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                cintas: p,
                              ),
                            ),
                    ),
                    _PermissionSubModule(
                      title: 'Variedades',
                      icon: Icons.local_florist_rounded,
                      permission: _permissions.variedades,
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                variedades: p,
                              ),
                            ),
                    ),
                    _PermissionSubModule(
                      title: 'Fincas',
                      icon: Icons.landscape_rounded,
                      permission: _permissions.fincas,
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                fincas: p,
                              ),
                            ),
                    ),
                    _PermissionSubModule(
                      title: 'Lotes',
                      icon: Icons.grid_view_rounded,
                      permission: _permissions.lotes,
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                lotes: p,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── PRODUCCIÓN ──
                _PermissionModule(
                  title: 'Producción',
                  icon: Icons.agriculture_rounded,
                  color: AppColors.primary,
                  children: [
                    _PermissionSubModule(
                      title: 'Siembra',
                      icon: Icons.grass_rounded,
                      permission: _permissions.siembra,
                      actions: const ['ver', 'crear'],
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                siembra: p,
                              ),
                            ),
                    ),
                    _PermissionSubModule(
                      title: 'Encintado',
                      icon: Icons.confirmation_number_rounded,
                      permission: _permissions.encintado,
                      actions: const ['ver', 'crear'],
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                encintado: p,
                              ),
                            ),
                    ),
                    _PermissionSubModule(
                      title: 'Cosecha',
                      icon: Icons.agriculture_rounded,
                      permission: _permissions.cosecha,
                      actions: const ['ver', 'crear'],
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                cosecha: p,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── CONSULTAS ──
                _PermissionModule(
                  title: 'Consultas',
                  icon: Icons.query_stats_rounded,
                  color: AppColors.info,
                  children: [
                    _PermissionSubModule(
                      title: 'Consultas',
                      icon: Icons.query_stats_rounded,
                      permission: _permissions.consultas,
                      actions: const ['ver'],
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                consultas: p,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── USUARIOS ──
                _PermissionModule(
                  title: 'Usuarios',
                  icon: Icons.people_rounded,
                  color: AppColors.secondary,
                  children: [
                    _PermissionSubModule(
                      title: 'Gestión de Usuarios',
                      icon: Icons.people_rounded,
                      permission: _permissions.usuarios,
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                usuarios: p,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── CONFIGURACIÓN DE EMPRESA ──
                _PermissionModule(
                  title: 'Configuración Empresa',
                  icon: Icons.settings_rounded,
                  color: Colors.blueGrey,
                  children: [
                    _PermissionSubModule(
                      title: 'Ajustes de Empresa',
                      icon: Icons.manage_accounts_rounded,
                      permission: _permissions.ajustesEmpresa,
                      actions: const ['ver', 'editar'], // Solo ver y editar
                      onChanged: widget.readOnly
                          ? (_) {}
                          : (p) => setState(
                              () => _permissions = _permissions.copyWith(
                                ajustesEmpresa: p,
                              ),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],

              // --- Botón Acción ---
              if (!widget.readOnly)
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isEditing
                                ? Icons.save_rounded
                                : Icons.person_add_rounded,
                          ),
                    label: Text(
                      _isSubmitting
                          ? (_isEditing ? 'Guardando...' : 'Creando...')
                          : (_isEditing ? 'Guardar Cambios' : 'Crear Empleado'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

              // --- Botón Desactivar (solo edición, no es owner) ---
              if (!widget.readOnly &&
                  _isEditing &&
                  !widget.existingUser!.isOwner) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _toggleActive,
                    icon: Icon(
                      widget.existingUser!.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      widget.existingUser!.isActive
                          ? 'Desactivar Empleado'
                          : 'Activar Empleado',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.existingUser!.isActive
                          ? AppColors.error
                          : AppColors.estadoCosechado,
                      side: BorderSide(
                        color: widget.existingUser!.isActive
                            ? AppColors.error.withValues(alpha: 0.3)
                            : AppColors.estadoCosechado.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(
      usersNotifierProvider((
        companyId: widget.companyId,
        companyRole: widget.companyRole,
      )).notifier,
    );

    if (_isEditing) {
      await notifier.updateEmployee(
        uid: widget.existingUser!.uid,
        displayName: _nameController.text.trim(),
        permissions: _permissions,
      );
    } else {
      await notifier.createEmployee(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        permissions: _permissions,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      final state = ref.read(
        usersNotifierProvider((
          companyId: widget.companyId,
          companyRole: widget.companyRole,
        )),
      );

      if (state.error == null) {
        if (_isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Cambios guardados correctamente'),
                ],
              ),
              backgroundColor: AppColors.estadoCosechado,
            ),
          );
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _toggleActive() async {
    if (!_isEditing) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(
      usersNotifierProvider((
        companyId: widget.companyId,
        companyRole: widget.companyRole,
      )).notifier,
    );

    await notifier.toggleActive(
      widget.existingUser!.uid,
      widget.existingUser!.isActive,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
    }
  }
}

// ══════════════════════════════════════════════════════════
// WIDGETS DE PERMISOS
// ══════════════════════════════════════════════════════════

/// Contenedor de un grupo de permisos (por módulo padre)
class _PermissionModule extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_PermissionSubModule> children;

  const _PermissionModule({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 12,
          ),
          children: children,
        ),
      ),
    );
  }
}

/// Widget para un sub-módulo individual con sus toggles de acciones
class _PermissionSubModule extends StatelessWidget {
  final String title;
  final IconData icon;
  final ModulePermission permission;
  final ValueChanged<ModulePermission> onChanged;

  /// Acciones disponibles. Default: ['ver', 'crear', 'editar', 'eliminar']
  final List<String> actions;

  const _PermissionSubModule({
    required this.title,
    required this.icon,
    required this.permission,
    required this.onChanged,
    this.actions = const ['ver', 'crear', 'editar', 'eliminar'],
  });

  bool _getValue(String action) {
    return switch (action) {
      'ver' => permission.ver,
      'crear' => permission.crear,
      'editar' => permission.editar,
      'eliminar' => permission.eliminar,
      _ => false,
    };
  }

  ModulePermission _setValue(String action, bool value) {
    // Si se desactiva "ver", desactivar todo
    if (action == 'ver' && !value) {
      return const ModulePermission.none();
    }

    var result = permission;

    // Si se activa cualquier acción que no sea "ver", activar "ver" automáticamente
    if (action != 'ver' && value && !permission.ver) {
      result = result.copyWith(ver: true);
    }

    return switch (action) {
      'ver' => result.copyWith(ver: value),
      'crear' => result.copyWith(crear: value),
      'editar' => result.copyWith(editar: value),
      'eliminar' => result.copyWith(eliminar: value),
      _ => result,
    };
  }

  String _actionLabel(String action) {
    return switch (action) {
      'ver' => 'Ver',
      'crear' => 'Crear',
      'editar' => 'Editar',
      'eliminar' => 'Eliminar',
      _ => action,
    };
  }

  Color _actionColor(String action) {
    return switch (action) {
      'ver' => AppColors.info,
      'crear' => AppColors.primary,
      'editar' => AppColors.accent,
      'eliminar' => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: actions.map((action) {
              final isActive = _getValue(action);
              final color = _actionColor(action);
              return FilterChip(
                label: Text(
                  _actionLabel(action),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isActive,
                onSelected: (v) => onChanged(_setValue(action, v)),
                selectedColor: color,
                backgroundColor: AppColors.background,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isActive ? color : AppColors.borderLight,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
