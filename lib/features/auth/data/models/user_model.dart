import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:json_annotation/json_annotation.dart'; // Removed
import '../../domain/entities/app_user.dart';
import '../../../../core/constants/role_constants.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.email,
    required super.role,
    super.companyId,
    super.displayName,
    super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['correo'] as String,
      role: _stringToRole(json['rol'] as String),
      companyId: json['id_empresa'] as String?,
      displayName: json['nombre'] as String?,
      isActive: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // UID eliminado ya que es el ID del documento
      'correo': email,
      'rol': _roleToString(role),
      'id_empresa': companyId,
      'nombre': displayName,
      'activo': isActive,
      // fechas se manejan en datasource
    };
  }

  static UserRole _stringToRole(String roleStr) {
    return UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.productora, // Default fallback
    );
  }

  static String _roleToString(UserRole role) => role.name;

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Priorizamos doc.id sobre cualquier campo 'uid' que pudiera existir en data
    return UserModel.fromJson({...data, 'uid': doc.id});
  }

  // Custom fromEntity
  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      role: user.role,
      companyId: user.companyId,
      displayName: user.displayName,
      isActive: user.isActive,
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
    );
  }
}
