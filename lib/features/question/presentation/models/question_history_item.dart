class QuestionHistoryItem {
  const QuestionHistoryItem({
    required this.question,
    required this.answer,
    required this.createdAtLabel,
    this.isNew = false,
  });

  final String question;
  final String answer;
  final String createdAtLabel;
  final bool isNew;
}
