import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<Result<AppUser>> signIn(String email, String password);

  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required UserRole role,
    required String companyName,
    required String location,
    required String rnt,
  });

  Future<void> signOut();

  Future<Result<AppUser>> getCurrentUser();
}
