import 'package:diyalizmobile/core/constants/api_endpoints.dart';
import 'package:diyalizmobile/core/network/api_client.dart';
import 'package:diyalizmobile/core/network/api_result.dart';

class ModulesRemoteDataSource {
  ModulesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<Map<String, dynamic>>> getMyModules() {
    return _apiClient.get(ApiEndpoints.myModules);
  }

  Future<ApiResult<Map<String, dynamic>>> getModuleContent(
    String moduleId,
  ) async {
    final parsedModuleId = int.tryParse(moduleId);
    final detailResult = await _apiClient.get(
      ApiEndpoints.moduleDetail,
      queryParameters: {'id': parsedModuleId ?? moduleId},
    );
    if (detailResult case ApiSuccess<Map<String, dynamic>>()) {
      return detailResult;
    }

    final primaryResult = await _apiClient.get(
      ApiEndpoints.moduleContent,
      queryParameters: {'module_id': parsedModuleId ?? moduleId},
    );
    if (primaryResult case ApiSuccess<Map<String, dynamic>>()) {
      return primaryResult;
    }

    return _apiClient.get(ApiEndpoints.moduleContentLegacy(moduleId));
  }

  Future<ApiResult<Map<String, dynamic>>> getContentDetail(String contentId) {
    final parsedContentId = int.tryParse(contentId);
    return _apiClient.get(
      ApiEndpoints.contentDetail,
      queryParameters: {'id': parsedContentId ?? contentId},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> sendProgress({
    required String moduleId,
    required int pageIndex,
    String? contentId,
  }) async {
    final parsedModuleId = int.tryParse(moduleId);
    if (contentId != null && contentId.trim().isNotEmpty) {
      final parsedContentId = int.tryParse(contentId);
      final progressResult = await _apiClient.post(
        ApiEndpoints.progressUpdate,
        data: {
          'module_id': parsedModuleId ?? moduleId,
          'content_id': parsedContentId ?? contentId,
        },
      );
      if (progressResult case ApiSuccess<Map<String, dynamic>>()) {
        return progressResult;
      }
    }

    final payload = {
      'module_id': parsedModuleId ?? moduleId,
      'page_index': pageIndex,
      'pageIndex': pageIndex,
    };
    final primaryResult = await _apiClient.post(
      ApiEndpoints.moduleProgress,
      data: payload,
    );
    if (primaryResult case ApiSuccess<Map<String, dynamic>>()) {
      return primaryResult;
    }
    return _apiClient.post(
      ApiEndpoints.moduleProgressLegacy(moduleId),
      data: {'pageIndex': pageIndex},
    );
  }
}
