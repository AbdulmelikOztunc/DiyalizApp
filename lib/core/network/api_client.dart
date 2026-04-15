import 'package:diyalizmobile/core/network/api_error.dart';
import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return ApiSuccess(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      return ApiFailure(_toApiError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return ApiSuccess(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      return ApiFailure(_toApiError(e));
    }
  }

  ApiError _toApiError(DioException e) {
    final body = e.response?.data;
    String? code;
    String message = e.message ?? 'Beklenmeyen bir hata oluştu';
    if (body is Map<String, dynamic>) {
      code = body['code'] as String?;
      message = (body['message'] as String?) ?? message;
    }
    return ApiError(
      message: message,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}
