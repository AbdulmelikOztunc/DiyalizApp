import 'package:diyalizmobile/core/constants/api_endpoints.dart';
import 'package:diyalizmobile/core/network/api_client.dart';
import 'package:diyalizmobile/core/network/api_result.dart';

class QuestionRemoteDataSource {
  QuestionRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<Map<String, dynamic>>> sendQuestion({
    required String message,
    required String moduleId,
  }) {
    final parsedModuleId = int.tryParse(moduleId);
    return _apiClient.post(
      ApiEndpoints.questions,
      data: {
        'question': message,
        'module_id': parsedModuleId ?? moduleId,
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> getQuestions({String? moduleId}) {
    return _apiClient.get(
      ApiEndpoints.questionsList,
      queryParameters: moduleId == null ? null : {'module_id': moduleId},
    );
  }
}
