import '../../../../core/constants/role_constants.dart';
import '../../../../core/constants/user_permissions.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/data/models/user_model.dart';

/// Contrato del repositorio de gestión de usuarios de una empresa.
abstract class UsersRepository {
  Future<Result<UserModel>> createEmployee({
    required String email,
    required String password,
    required String displayName,
    required UserPermissions permissions,
    required String companyId,
    required UserRole companyRole,
  });

  Future<Result<List<UserModel>>> getEmployees(String companyId);

  Future<Result<void>> updateEmployee({
    required String uid,
    String? displayName,
    UserPermissions? permissions,
    bool? isActive,
  });

  Future<Result<void>> deactivateEmployee(String uid);
}
