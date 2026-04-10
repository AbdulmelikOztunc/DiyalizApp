import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/core/network/dio_providers.dart';
import 'package:diyalizmobile/features/question/data/datasources/question_remote_data_source.dart';
import 'package:diyalizmobile/features/question/data/repositories/question_repository_impl.dart';
import 'package:diyalizmobile/features/question/domain/repositories/question_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionState {
  const QuestionState({
    this.isSending = false,
    this.successMessage,
    this.errorMessage,
  });

  final bool isSending;
  final String? successMessage;
  final String? errorMessage;

  QuestionState copyWith({
    bool? isSending,
    String? successMessage,
    String? errorMessage,
  }) {
    return QuestionState(
      isSending: isSending ?? this.isSending,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl(
    QuestionRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final questionControllerProvider =
    NotifierProvider<QuestionController, QuestionState>(
  QuestionController.new,
);

class QuestionController extends Notifier<QuestionState> {
  @override
  QuestionState build() => const QuestionState();

  Future<void> sendQuestion(String message) async {
    state = state.copyWith(
      isSending: true,
      successMessage: null,
      errorMessage: null,
    );

    final result =
        await ref.read(questionRepositoryProvider).sendQuestion(message: message);
    switch (result) {
      case ApiSuccess<void>():
        state = state.copyWith(
          isSending: false,
          successMessage: 'Sorunuz alindi',
          errorMessage: null,
        );
      case ApiFailure<void>(:final error):
        state = state.copyWith(
          isSending: false,
          successMessage: null,
          errorMessage: error.message,
        );
    }
  }
}
