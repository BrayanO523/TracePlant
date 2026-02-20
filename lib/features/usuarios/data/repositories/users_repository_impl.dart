import '../../../../core/constants/role_constants.dart';
import '../../../../core/constants/user_permissions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_datasource.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDatasource _datasource;

  UsersRepositoryImpl(this._datasource);

  @override
  Future<Result<UserModel>> createEmployee({
    required String email,
    required String password,
    required String displayName,
    required UserPermissions permissions,
    required String companyId,
    required UserRole companyRole,
  }) async {
    try {
      final user = await _datasource.createEmployee(
        email: email,
        password: password,
        displayName: displayName,
        permissions: permissions,
        companyId: companyId,
        companyRole: companyRole,
      );
      return Success(user);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<UserModel>>> getEmployees(String companyId) async {
    try {
      final users = await _datasource.getEmployees(companyId);
      return Success(users);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateEmployee({
    required String uid,
    String? displayName,
    UserPermissions? permissions,
    bool? isActive,
  }) async {
    try {
      await _datasource.updateEmployee(
        uid: uid,
        displayName: displayName,
        permissions: permissions,
        isActive: isActive,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deactivateEmployee(String uid) async {
    try {
      await _datasource.deactivateEmployee(uid);
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
