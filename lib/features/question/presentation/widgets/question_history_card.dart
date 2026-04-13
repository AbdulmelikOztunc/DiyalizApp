import 'package:diyalizmobile/features/question/presentation/models/question_history_item.dart';
import 'package:flutter/material.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _mediumPurple = Color(0xFFE0D7FF);
const _softPurple = Color(0xFFB0A8E3);

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _mediumPurple.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Yeni',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                item.createdAtLabel,
                style: TextStyle(
                  color: _softPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: _mediumPurple.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 14,
                  color: _primaryPurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.answer.trim().isEmpty)
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Henüz yanıtlanmadı',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.answer,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
