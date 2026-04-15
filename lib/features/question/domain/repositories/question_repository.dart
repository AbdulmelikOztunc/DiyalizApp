import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/question/presentation/models/question_history_item.dart';

abstract class QuestionRepository {
  Future<ApiResult<String>> sendQuestion({
    required String message,
    required String moduleId,
  });

  Future<ApiResult<List<QuestionHistoryItem>>> getQuestions({String? moduleId});
}
