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
    if (detailResult case ApiSuccess<Map<String, dynamic>>(:final data)) {
      if (_hasUsableContentPayload(data)) {
        return detailResult;
      }
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

  bool _hasUsableContentPayload(Map<String, dynamic> data) {
    final rootContents = data['contents'];
    if (rootContents is List && rootContents.isNotEmpty) return true;
    final module = data['module'];
    if (module is Map<String, dynamic>) {
      final moduleContents = module['contents'];
      if (moduleContents is List && moduleContents.isNotEmpty) return true;
      final moduleContent = module['content'];
      if (moduleContent is Map<String, dynamic>) return true;
    }
    final directContent = data['content'];
    if (directContent is Map<String, dynamic>) return true;
    final contentPages = data['content_pages'] ?? data['contentPages'];
    if (contentPages is List && contentPages.isNotEmpty) return true;
    return false;
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
