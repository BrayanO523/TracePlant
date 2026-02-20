import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/constants/user_permissions.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.email,
    required super.role,
    super.companyId,
    super.displayName,
    super.isActive,
    super.isOwner,
    super.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Determinar si es dueño
    final esDueno = json['es_dueno'] as bool? ?? false;

    // Retrocompatibilidad: si no tiene 'permisos' ni 'es_dueno',
    // pero tiene 'sub_rol', migrar según el sub-rol anterior
    UserPermissions permisos;
    if (json['permisos'] != null) {
      permisos = UserPermissions.fromJson(
        json['permisos'] as Map<String, dynamic>,
      );
    } else if (esDueno ||
        json['sub_rol'] == 'owner' ||
        json['sub_rol'] == null) {
      permisos = const UserPermissions.owner();
    } else {
      // sub_rol era supervisor u operario → migrar con defaults razonables
      permisos = const UserPermissions.none();
    }

    return UserModel(
      uid: json['uid'] as String,
      email: json['correo'] as String,
      role: _stringToRole(json['rol'] as String),
      companyId: json['id_empresa'] as String?,
      displayName: json['nombre'] as String?,
      isActive: json['activo'] as bool? ?? true,
      isOwner:
          esDueno ||
          json['sub_rol'] == 'owner' ||
          json['sub_rol'] == null && json['permisos'] == null,
      permissions: permisos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correo': email,
      'rol': _roleToString(role),
      'id_empresa': companyId,
      'nombre': displayName,
      'activo': isActive,
      'es_dueno': isOwner,
      if (!isOwner) 'permisos': permissions.toJson(),
    };
  }

  static UserRole _stringToRole(String roleStr) {
    return UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.productora,
    );
  }

  static String _roleToString(UserRole role) => role.name;

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'uid': doc.id});
  }

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      role: user.role,
      companyId: user.companyId,
      displayName: user.displayName,
      isActive: user.isActive,
      isOwner: user.isOwner,
      permissions: user.permissions,
    );
  }

  AppUser toEntity() {
    return AppUser(
      uid: uid,
      email: email,
      role: role,
      companyId: companyId,
      displayName: displayName,
      isActive: isActive,
      isOwner: isOwner,
      permissions: permissions,
    );
  }
}
