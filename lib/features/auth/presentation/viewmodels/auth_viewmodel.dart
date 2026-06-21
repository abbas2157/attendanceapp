import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/services/auth_storage.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_viewmodel.g.dart';

enum AuthStep { idle, loading, success, error }

class AuthState {
  final AuthStep step;
  final AuthModel? user;
  final String? errorMessage;
  final bool isLoggedIn;

  const AuthState({
    this.step = AuthStep.idle,
    this.user,
    this.errorMessage,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    AuthStep? step,
    AuthModel? user,
    String? errorMessage,
    bool? isLoggedIn,
    bool clearError = false,
  }) {
    return AuthState(
      step: step ?? this.step,
      user: user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  AuthState build() {
    Future.microtask(_loadStoredAuth);
    return const AuthState();
  }

  // ── Load stored auth on app start ─────────────────────────────────────────
  Future<void> _loadStoredAuth() async {
    final data = await AuthStorage.loadAuth();
    if (data != null) {
      state = state.copyWith(
        isLoggedIn: true,
        user: AuthModel.fromJson(data),
        step: AuthStep.success,
      );
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(step: AuthStep.loading, clearError: true);

    final result = await ref
        .read(authRepositoryProvider)
        .login(username: username, password: password);

    switch (result) {
      case ApiSuccess(:final data):
        // Save to SharedPreferences
        await AuthStorage.saveAuth(
          access: data.access,
          refresh: data.refresh,
          id: data.id,
          username: data.username,
          name: data.name,
          email: data.email,
        );
        state = state.copyWith(
          step: AuthStep.success,
          user: data,
          isLoggedIn: true,
        );
      case ApiError(:final message):
        state = state.copyWith(step: AuthStep.error, errorMessage: message);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await AuthStorage.clearAuth();
    state = const AuthState();
  }
}
