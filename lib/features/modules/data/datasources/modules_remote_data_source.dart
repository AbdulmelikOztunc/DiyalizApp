import 'package:diyalizmobile/core/constants/api_endpoints.dart';
import 'package:diyalizmobile/core/network/api_client.dart';
import 'package:diyalizmobile/core/network/api_result.dart';

class ModulesRemoteDataSource {
  ModulesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<Map<String, dynamic>>> getMyModules() {
    return _apiClient.get(ApiEndpoints.myModules);
  }

  Future<ApiResult<Map<String, dynamic>>> getModuleContent(String moduleId) {
    return _apiClient.get(ApiEndpoints.moduleContent(moduleId));
  }

  Future<ApiResult<Map<String, dynamic>>> sendProgress({
    required String moduleId,
    required int pageIndex,
  }) {
    return _apiClient.post(
      ApiEndpoints.moduleProgress(moduleId),
      data: {'pageIndex': pageIndex},
    );
  }
}
