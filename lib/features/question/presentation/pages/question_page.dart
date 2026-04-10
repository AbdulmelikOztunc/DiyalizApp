import 'package:diyalizmobile/features/question/presentation/controllers/question_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Arastirmaciya Sor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Sorunuzu buraya yazin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
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
