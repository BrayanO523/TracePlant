import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Stream<AppUser?> get authStateChanges {
    return _datasource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final userModel = await _datasource.getUserProfile(firebaseUser.uid);
        return userModel;
      } catch (_) {
        // If profile fetch fails, treat as not logged in or handle gracefully
        return null;
      }
    });
  }

  @override
  Future<Result<AppUser>> signIn(String email, String password) async {
    try {
      final userModel = await _datasource.signIn(email, password);
      return Success(userModel);
    } on Failure catch (e) {
      return FailureResult(e);
    } catch (e) {
      return const FailureResult(ServerFailure());
    }
  }

  @override
  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required UserRole role,
    required String companyName,
    required String location,
    required String rnt,
  }) async {
    try {
      final userModel = await _datasource.register(
        email: email,
        password: password,
        role: role,
        companyName: companyName,
        location: location,
        rnt: rnt,
      );
      return Success(userModel);
    } on Failure catch (e) {
      return FailureResult(e);
    } catch (e) {
      return const FailureResult(ServerFailure());
    }
  }

  @override
  Future<void> signOut() async {
    await _datasource.signOut();
  }

  @override
  Future<Result<AppUser>> getCurrentUser() async {
    try {
      final userModel = await _datasource.getCurrentUser();
      return Success(userModel);
    } on Failure catch (e) {
      return FailureResult(e);
    } catch (e) {
      return const FailureResult(ServerFailure());
    }
  }
}
