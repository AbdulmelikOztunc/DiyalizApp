import 'package:diyalizmobile/core/constants/api_endpoints.dart';
import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/core/network/dio_providers.dart';
import 'package:diyalizmobile/core/settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.get(ApiEndpoints.settings);
  return switch (result) {
    ApiSuccess<Map<String, dynamic>>(:final data) => AppSettings.fromResponse(data),
    ApiFailure<Map<String, dynamic>>(:final error) =>
      throw Exception(error.message),
  };
});
