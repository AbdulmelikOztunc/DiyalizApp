import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/auth/domain/entities/user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final User user;
}

abstract class AuthRepository {
  Future<ApiResult<AuthSession>> login({
    required String phoneNumber,
    required String password,
  });
  Future<ApiResult<AuthSession>> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
  });
  Future<void> logout();
  Future<AuthSession?> getCachedSession();
}
