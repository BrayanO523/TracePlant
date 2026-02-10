import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../app/di/providers.dart';

class AuthNotifier extends AsyncNotifier<void> {
  late final AuthRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(authRepositoryProvider);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.signIn(email, password);

    switch (result) {
      case Success():
        state = const AsyncValue.data(null);
      case FailureResult(failure: final f):
        state = AsyncValue.error(f.message, StackTrace.current);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required UserRole role,
    required String companyName,
    required String location,
    required String rnt,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.register(
      email: email,
      password: password,
      role: role,
      companyName: companyName,
      location: location,
      rnt: rnt,
    );

    switch (result) {
      case Success():
        state = const AsyncValue.data(null);
      case FailureResult(failure: final f):
        state = AsyncValue.error(f.message, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
