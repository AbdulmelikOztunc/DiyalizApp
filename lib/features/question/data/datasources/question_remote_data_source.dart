import 'package:diyalizmobile/core/constants/api_endpoints.dart';
import 'package:diyalizmobile/core/network/api_client.dart';
import 'package:diyalizmobile/core/network/api_result.dart';

class QuestionRemoteDataSource {
  QuestionRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<Map<String, dynamic>>> sendQuestion(String message) {
    return _apiClient.post(
      ApiEndpoints.questions,
      data: {'message': message},
    );
  }
}
