import 'dart:convert';

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
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return ApiSuccess(_asMap(response.data));
    } on DioException catch (e) {
      return ApiFailure(_toApiError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return ApiSuccess(_asMap(response.data));
    } on DioException catch (e) {
      return ApiFailure(_toApiError(e));
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw == null) return <String, dynamic>{};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    if (raw is List) {
      return <String, dynamic>{'items': raw};
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return <String, dynamic>{};
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
        if (decoded is List) {
          return <String, dynamic>{'items': decoded};
        }
      } catch (_) {
        // fall through
      }
      return <String, dynamic>{'raw': raw};
    }
    return <String, dynamic>{'raw': raw};
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
