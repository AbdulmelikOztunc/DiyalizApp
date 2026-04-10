import 'dart:convert';

import 'package:diyalizmobile/core/network/api_error.dart';
import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/core/storage/secure_storage_service.dart';
import 'package:diyalizmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:diyalizmobile/features/auth/domain/entities/user.dart';
import 'package:diyalizmobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorageService,
    required SharedPreferences sharedPreferences,
  }) : _remoteDataSource = remoteDataSource,
       _secureStorageService = secureStorageService,
       _sharedPreferences = sharedPreferences;

  static const _cachedUserKey = 'cached_user';
  static const _useMockLogin = true;
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorageService;
  final SharedPreferences _sharedPreferences;

  @override
  Future<AuthSession?> getCachedSession() async {
    final token = await _secureStorageService.readToken();
    final rawUser = _sharedPreferences.getString(_cachedUserKey);
    if (token == null || rawUser == null) {
      return null;
    }

    final map = jsonDecode(rawUser) as Map<String, dynamic>;
    return AuthSession(
      token: token,
      user: User(
        id: map['id'] as String? ?? '',
        fullName: map['fullName'] as String? ?? 'Kullanici',
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> login({
    required String phoneNumber,
    required String password,
  }) async {
    if (_useMockLogin) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final session = AuthSession(
        token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
        user: User(id: 'mock-user-1', fullName: 'Demo Kullanıcı'),
      );

      await _secureStorageService.saveToken(session.token);
      await _sharedPreferences.setString(
        _cachedUserKey,
        jsonEncode({'id': session.user.id, 'fullName': session.user.fullName}),
      );

      return ApiSuccess(session);
    }

    final response = await _remoteDataSource.login(
      phoneNumber: phoneNumber,
      password: password,
    );

    if (response case ApiFailure(:final error)) {
      return ApiFailure(error);
    }

    final data = (response as ApiSuccess<Map<String, dynamic>>).data;
    final token = data['token'] as String?;
    final userMap = data['user'] as Map<String, dynamic>?;

    if (token == null || userMap == null) {
      return const ApiFailure(ApiError(message: 'Giris yaniti gecersiz'));
    }

    final session = AuthSession(
      token: token,
      user: User(
        id: userMap['id'] as String? ?? '',
        fullName: userMap['fullName'] as String? ?? 'Kullanici',
      ),
    );

    await _secureStorageService.saveToken(token);
    await _sharedPreferences.setString(
      _cachedUserKey,
      jsonEncode({'id': session.user.id, 'fullName': session.user.fullName}),
    );

    return ApiSuccess(session);
  }

  @override
  Future<void> logout() async {
    await _secureStorageService.clearToken();
    await _sharedPreferences.remove(_cachedUserKey);
  }
}
