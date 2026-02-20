import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/constants/user_permissions.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/repositories/users_repository.dart';

/// Estado de la pantalla de gestión de usuarios
class UsersState {
  final List<UserModel> employees;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const UsersState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  UsersState copyWith({
    List<UserModel>? employees,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return UsersState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  final UsersRepository _repository;
  final String companyId;
  final UserRole companyRole;

  UsersNotifier({
    required UsersRepository repository,
    required this.companyId,
    required this.companyRole,
  }) : _repository = repository,
       super(const UsersState(isLoading: true)) {
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getEmployees(companyId);

    switch (result) {
      case Success(data: final employees):
        state = state.copyWith(employees: employees, isLoading: false);
      case FailureResult(failure: final f):
        state = state.copyWith(isLoading: false, error: f.message);
    }
  }

  Future<void> createEmployee({
    required String email,
    required String password,
    required String displayName,
    required UserPermissions permissions,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createEmployee(
      email: email,
      password: password,
      displayName: displayName,
      permissions: permissions,
      companyId: companyId,
      companyRole: companyRole,
    );

    switch (result) {
      case Success(data: final user):
        state = state.copyWith(
          employees: [...state.employees, user],
          isLoading: false,
          successMessage: 'Empleado "${user.displayName}" creado exitosamente',
        );
      case FailureResult(failure: final f):
        state = state.copyWith(
          isLoading: false,
          error: 'Error al crear empleado: ${f.message}',
        );
    }
  }

  Future<void> updateEmployee({
    required String uid,
    String? displayName,
    UserPermissions? permissions,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateEmployee(
      uid: uid,
      displayName: displayName,
      permissions: permissions,
      isActive: isActive,
    );

    switch (result) {
      case Success():
        // Recargar lista para reflejar cambios
        await loadEmployees();
        state = state.copyWith(successMessage: 'Empleado actualizado');
      case FailureResult(failure: final f):
        state = state.copyWith(
          isLoading: false,
          error: 'Error al actualizar: ${f.message}',
        );
    }
  }

  Future<void> toggleActive(String uid, bool currentlyActive) async {
    await updateEmployee(uid: uid, isActive: !currentlyActive);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
