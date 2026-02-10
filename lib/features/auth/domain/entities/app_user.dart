import 'package:equatable/equatable.dart';
import '../../../../core/constants/role_constants.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final UserRole role;
  final String? companyId;
  final String? displayName;
  final bool isActive;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.companyId,
    this.displayName,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    role,
    companyId,
    displayName,
    isActive,
  ];
}
