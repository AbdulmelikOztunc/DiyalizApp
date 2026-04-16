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
  static const _cachedPhoneKey = 'cached_phone';
  static const _notificationEmailKey = 'notification_email';
  static const _useMockLogin = false;
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
    final phone = phoneNumber.trim();
    if (phone.isEmpty) {
      return const ApiFailure(ApiError(message: 'Telefon numarası gerekli'));
    }
    if (password.length < 6) {
      return const ApiFailure(
        ApiError(message: 'Şifre en az 6 hane olmalı'),
      );
    }
    if (!_isDigitsOnly(password)) {
      return const ApiFailure(
        ApiError(message: 'Şifre sadece rakamlardan oluşmalı'),
      );
    }

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
      await _sharedPreferences.setString(_cachedPhoneKey, '5551234567');
      await _sharedPreferences.setString(_notificationEmailKey, 'demo@diyaliz.com');

      return ApiSuccess(session);
    }

    final response = await _remoteDataSource.login(phoneNumber: phone, password: password);

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
        id: '${userMap['id'] ?? ''}',
        fullName: (userMap['full_name'] as String?) ??
            (userMap['fullName'] as String?) ??
            'Kullanici',
      ),
    );

    await _secureStorageService.saveToken(token);
    await _sharedPreferences.setString(
      _cachedUserKey,
      jsonEncode({'id': session.user.id, 'fullName': session.user.fullName}),
    );
    await _sharedPreferences.setString(_cachedPhoneKey, phone);
    final loginEmail = (userMap['email'] as String?)?.trim();
    if (loginEmail != null && loginEmail.isNotEmpty) {
      await _sharedPreferences.setString(_notificationEmailKey, loginEmail);
    } else {
      await _sharedPreferences.remove(_notificationEmailKey);
    }

    return ApiSuccess(session);
  }

  @override
  Future<ApiResult<AuthSession>> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
  }) async {
    final trimmedFullName = fullName.trim();
    if (trimmedFullName.isEmpty) {
      return const ApiFailure(ApiError(message: 'Ad soyad gerekli'));
    }

    final phone = phoneNumber.trim();
    if (phone.isEmpty) {
      return const ApiFailure(ApiError(message: 'Telefon numarası gerekli'));
    }
    if (password.length < 6) {
      return const ApiFailure(
        ApiError(message: 'Şifre en az 6 hane olmalı'),
      );
    }
    if (!_isDigitsOnly(password)) {
      return const ApiFailure(
        ApiError(message: 'Şifre sadece rakamlardan oluşmalı'),
      );
    }

    final trimmedEmail = email?.trim();
    if (trimmedEmail != null &&
        trimmedEmail.isNotEmpty &&
        !_looksLikeEmail(trimmedEmail)) {
      return const ApiFailure(ApiError(message: 'Geçerli bir e-posta girin'));
    }

    if (_useMockLogin) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final session = AuthSession(
        token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
        user: User(
          id: 'mock-user-${phone.hashCode}',
          fullName: trimmedFullName,
        ),
      );

      await _secureStorageService.saveToken(session.token);
      await _sharedPreferences.setString(
        _cachedUserKey,
        jsonEncode({'id': session.user.id, 'fullName': session.user.fullName}),
      );
      await _sharedPreferences.setString(_cachedPhoneKey, phone);

      if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
        await _sharedPreferences.setString(_notificationEmailKey, trimmedEmail);
      } else {
        await _sharedPreferences.remove(_notificationEmailKey);
      }

      return ApiSuccess(session);
    }

    final response = await _remoteDataSource.register(
      fullName: trimmedFullName,
      phoneNumber: phone,
      password: password,
      email: (trimmedEmail == null || trimmedEmail.isEmpty)
          ? null
          : trimmedEmail,
    );

    if (response case ApiFailure(:final error)) {
      return ApiFailure(error);
    }

    final data = (response as ApiSuccess<Map<String, dynamic>>).data;
    final token = data['token'] as String?;
    final userMap = data['user'] as Map<String, dynamic>?;

    if (token == null || userMap == null) {
      return const ApiFailure(ApiError(message: 'Kayıt yanıtı geçersiz'));
    }

    final session = AuthSession(
      token: token,
      user: User(
        id: '${userMap['id'] ?? ''}',
        fullName: (userMap['full_name'] as String?) ??
            (userMap['fullName'] as String?) ??
            trimmedFullName,
      ),
    );

    await _secureStorageService.saveToken(token);
    await _sharedPreferences.setString(
      _cachedUserKey,
      jsonEncode({'id': session.user.id, 'fullName': session.user.fullName}),
    );
    await _sharedPreferences.setString(_cachedPhoneKey, phone);

    final responseEmail = (userMap['email'] as String?)?.trim();
    final emailToCache = (responseEmail != null && responseEmail.isNotEmpty)
        ? responseEmail
        : trimmedEmail;

    if (emailToCache != null && emailToCache.isNotEmpty) {
      await _sharedPreferences.setString(_notificationEmailKey, emailToCache);
    } else {
      await _sharedPreferences.remove(_notificationEmailKey);
    }

    return ApiSuccess(session);
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@([^@\s]+\.)+[^@\s]+$').hasMatch(value);
  }

  bool _isDigitsOnly(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  @override
  Future<void> logout() async {
    await _secureStorageService.clearToken();
    await _sharedPreferences.remove(_cachedUserKey);
    await _sharedPreferences.remove(_cachedPhoneKey);
    await _sharedPreferences.remove(_notificationEmailKey);
  }
}
