import 'package:diyalizmobile/features/question/presentation/data/question_history_dummy.dart';
import 'package:diyalizmobile/features/question/presentation/widgets/question_history_card.dart';
import 'package:flutter/material.dart';

const _questionPrimaryPurple = Color(0xFF4A35B8);

class QuestionHistoryPage extends StatelessWidget {
  const QuestionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gecmis Soru-Cevaplar'),
        centerTitle: true,
      ),
      body: kDummyQuestionHistory.isEmpty
          ? const _EmptyHistoryView()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = kDummyQuestionHistory[index];
                return QuestionHistoryCard(item: item);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: kDummyQuestionHistory.length,
            ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 46,
              color: _questionPrimaryPurple,
            ),
            const SizedBox(height: 10),
            const Text(
              'Henuz soru gecmisi yok',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Ilk sorunuzu gonderdiginde burada listelenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _questionPrimaryPurple.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
