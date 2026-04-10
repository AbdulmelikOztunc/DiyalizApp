import 'package:diyalizmobile/core/constants/api_endpoints.dart';
import 'package:diyalizmobile/core/network/api_client.dart';
import 'package:diyalizmobile/core/network/api_result.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<Map<String, dynamic>>> login({
    required String phoneNumber,
    required String password,
  }) {
    return _apiClient.post(
      ApiEndpoints.login,
      data: {
        'phone': phoneNumber,
        'username': phoneNumber,
        'password': password,
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> register({
    required String phoneNumber,
    required String password,
    String? email,
  }) {
    return _apiClient.post(
      ApiEndpoints.register,
      data: {
        'phone': phoneNumber,
        'username': phoneNumber,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
  }
}
