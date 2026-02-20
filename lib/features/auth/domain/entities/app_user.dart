import 'package:equatable/equatable.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/constants/user_permissions.dart';

/// Entidad de usuario en el dominio.
class AppUser extends Equatable {
  final String uid;
  final String email;
  final UserRole role;
  final String? companyId;
  final String? displayName;
  final bool isActive;

  /// Si es el dueño de la empresa (all-access automático)
  final bool isOwner;

  /// Permisos granulares (solo aplica si NO es owner)
  final UserPermissions permissions;

  const AppUser({
    required this.uid,
    required this.email,
    this.role = UserRole.productora,
    this.companyId,
    this.displayName,
    this.isActive = true,
    this.isOwner = false,
    this.permissions = const UserPermissions.none(),
  });

  /// Permisos efectivos: si es owner → all-access; si no → sus permisos
  UserPermissions get effectivePermissions =>
      isOwner ? const UserPermissions.owner() : permissions;

  @override
  List<Object?> get props => [
    uid,
    email,
    role,
    companyId,
    displayName,
    isActive,
    isOwner,
    permissions,
  ];
}
