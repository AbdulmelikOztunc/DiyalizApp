import 'package:diyalizmobile/features/question/presentation/data/question_history_dummy.dart';
import 'package:diyalizmobile/features/question/presentation/widgets/question_history_card.dart';
import 'package:flutter/material.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);
const _deepPurple = Color(0xFF8B5CF6);
const _mediumPurple = Color(0xFFE0D7FF);

class QuestionHistoryPage extends StatelessWidget {
  const QuestionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_deepPurple, _darkPurple, _primaryPurple],
                stops: [0, 0.45, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x337C3AED),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'Geçmiş Soru-Cevaplar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: kDummyQuestionHistory.isEmpty
                ? const _EmptyHistoryView()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = kDummyQuestionHistory[index];
                      return QuestionHistoryCard(item: item);
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemCount: kDummyQuestionHistory.length,
                  ),
          ),
        ],
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _mediumPurple.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: _primaryPurple,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz soru geçmişi yok',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'İlk sorunuzu gönderdiğinizde burada listelenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _primaryPurple.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
