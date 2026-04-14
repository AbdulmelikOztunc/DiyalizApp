import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/core/network/dio_providers.dart';
import 'package:diyalizmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:diyalizmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:diyalizmobile/features/auth/domain/entities/user.dart';
import 'package:diyalizmobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(
        isLoading: false,
        isAuthenticated: false,
      );

  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final sharedPrefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(ref.watch(apiClientProvider)),
    secureStorageService: ref.watch(secureStorageServiceProvider),
    sharedPreferences: sharedPrefs,
  );
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return AuthState.initial();
  }

  Future<void> _restoreSession() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final session = await repo.getCachedSession();
    if (session == null) return;
    state = state.copyWith(
      isAuthenticated: true,
      user: session.user,
    );
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final repo = await ref.read(authRepositoryProvider.future);
    final result = await repo.login(
      phoneNumber: phoneNumber,
      password: password,
    );
    switch (result) {
      case ApiSuccess<AuthSession>(:final data):
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: data.user,
          errorMessage: null,
        );
      case ApiFailure<AuthSession>(:final error):
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: error.message,
        );
    }
  }

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final repo = await ref.read(authRepositoryProvider.future);
    final result = await repo.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      password: password,
      email: email,
    );
    switch (result) {
      case ApiSuccess<AuthSession>(:final data):
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: data.user,
          errorMessage: null,
        );
      case ApiFailure<AuthSession>(:final error):
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: error.message,
        );
    }
  }

  Future<void> logout() async {
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.logout();
    state = AuthState.initial();
  }

  void updateUserProfile({required String fullName}) {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(
      user: User(id: currentUser.id, fullName: fullName),
      errorMessage: null,
    );
  }
}
