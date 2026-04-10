import 'package:diyalizmobile/features/question/presentation/models/question_history_item.dart';
import 'package:flutter/material.dart';

const _questionPrimaryPurple = Color(0xFF4A35B8);
const _questionSoftPurple = Color(0xFFB0A8E3);
const _questionCardTint = Color(0xFFF3F0FF);

class QuestionHistoryCard extends StatelessWidget {
  const QuestionHistoryCard({
    required this.item,
    super.key,
  });

  final QuestionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _questionCardTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _questionSoftPurple.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _questionSoftPurple.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Yeni',
                    style: TextStyle(
                      fontSize: 11,
                      color: _questionPrimaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                item.createdAtLabel,
                style: TextStyle(
                  color: _questionPrimaryPurple.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          if (item.answer.trim().isEmpty)
            Text(
              'Henuz yanitlanmadi',
              style: TextStyle(
                color: _questionPrimaryPurple,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              item.answer,
              style: TextStyle(
                color: const Color(0xFF5F5A85),
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}
