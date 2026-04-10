import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/question/data/datasources/question_remote_data_source.dart';
import 'package:diyalizmobile/features/question/domain/repositories/question_repository.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this._remoteDataSource);

  final QuestionRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<void>> sendQuestion({required String message}) async {
    final result = await _remoteDataSource.sendQuestion(message);
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>() => const ApiSuccess<void>(null),
      ApiFailure<Map<String, dynamic>>(:final error) => ApiFailure<void>(error),
    };
  }
}
