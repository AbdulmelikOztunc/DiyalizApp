import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/question/data/datasources/question_remote_data_source.dart';
import 'package:diyalizmobile/features/question/domain/repositories/question_repository.dart';
import 'package:diyalizmobile/features/question/presentation/models/question_history_item.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this._remoteDataSource);

  final QuestionRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<String>> sendQuestion({
    required String message,
    required String moduleId,
  }) async {
    final result = await _remoteDataSource.sendQuestion(
      message: message,
      moduleId: moduleId,
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => ApiSuccess<String>(
          data['message'] as String? ?? 'Sorunuz basariyla iletildi.',
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => ApiFailure<String>(error),
    };
  }

  @override
  Future<ApiResult<List<QuestionHistoryItem>>> getQuestions({
    String? moduleId,
  }) async {
    final result = await _remoteDataSource.getQuestions(moduleId: moduleId);
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        ApiSuccess<List<QuestionHistoryItem>>(_mapQuestions(data)),
      ApiFailure<Map<String, dynamic>>(:final error) =>
        ApiFailure<List<QuestionHistoryItem>>(error),
    };
  }

  List<QuestionHistoryItem> _mapQuestions(Map<String, dynamic> data) {
    final rows = data['questions'] as List<dynamic>? ?? <dynamic>[];
    final mapped = rows.map((raw) {
      final item = raw as Map<String, dynamic>;
      final createdAtRaw = item['created_at']?.toString() ?? '';
      final answerRaw = item['answer']?.toString() ?? '';
      final answered = _toBool(item['is_answered']);
      final questionText = item['question']?.toString() ?? '';
      return QuestionHistoryItem(
        question: questionText,
        answer: answerRaw == 'null' ? '' : answerRaw,
        createdAtLabel: _formatDateLabel(createdAtRaw),
        isNew: !answered,
      );
    }).toList();
    return mapped;
  }

  String _formatDateLabel(String input) {
    final dt = DateTime.tryParse(input);
    if (dt == null) return input;
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }
}
