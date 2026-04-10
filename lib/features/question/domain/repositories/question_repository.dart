import 'package:diyalizmobile/core/network/api_result.dart';

abstract class QuestionRepository {
  Future<ApiResult<void>> sendQuestion({
    required String message,
  });
}
