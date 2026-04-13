import 'package:diyalizmobile/features/question/presentation/controllers/question_controller.dart';
import 'package:diyalizmobile/features/question/presentation/data/question_history_dummy.dart';
import 'package:diyalizmobile/features/question/presentation/pages/question_history_page.dart';
import 'package:diyalizmobile/features/question/presentation/widgets/question_history_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _questionPrimaryPurple = Color(0xFF4A35B8);
const _questionSoftPurple = Color(0xFFB0A8E3);

class QuestionPage extends ConsumerStatefulWidget {
  const QuestionPage({super.key});

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<QuestionPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionControllerProvider);
    final recentHistory = kDummyQuestionHistory.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arastirmaciya Sor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Sorunuzu buraya yazin',
                hintStyle: TextStyle(
                  color: _questionPrimaryPurple.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: const Color(0xFFF6F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _questionSoftPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _questionSoftPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: _questionPrimaryPurple,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _questionPrimaryPurple,
                ),
                onPressed: state.isSending
                    ? null
                    : () => ref
                        .read(questionControllerProvider.notifier)
                        .sendQuestion(_controller.text.trim()),
                child: state.isSending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gonder'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Son Soru-Cevaplar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _questionPrimaryPurple,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QuestionHistoryPage(),
                      ),
                    );
                  },
                  child: const Text('Tumunu Gor'),
                ),
              ],
            ),
            if (recentHistory.isEmpty)
              const Expanded(child: _EmptyHistoryPreview())
            else
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) =>
                      QuestionHistoryCard(item: recentHistory[index]),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: recentHistory.length,
                ),
              ),
            if (state.successMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryPreview extends StatelessWidget {
  const _EmptyHistoryPreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: _questionPrimaryPurple,
            size: 42,
          ),
          const SizedBox(height: 8),
          const Text(
            'Henuz soru yok',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Sordugun sorular burada cevaplariyla listelenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _questionPrimaryPurple.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
