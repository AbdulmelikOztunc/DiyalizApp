import 'package:diyalizmobile/features/question/presentation/controllers/question_controller.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:diyalizmobile/features/question/presentation/widgets/question_history_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);
const _deepPurple = Color(0xFF8B5CF6);
const _mediumPurple = Color(0xFFE0D7FF);
const _softPurple = Color(0xFFB0A8E3);

class QuestionHistoryPage extends ConsumerStatefulWidget {
  const QuestionHistoryPage({super.key});

  @override
  ConsumerState<QuestionHistoryPage> createState() => _QuestionHistoryPageState();
}

class _QuestionHistoryPageState extends ConsumerState<QuestionHistoryPage> {
  String? _selectedModuleId;
  bool _isTopicMenuOpen = false;

  @override
  void dispose() {
    if (_selectedModuleId != null) {
      ref.read(questionControllerProvider.notifier).loadQuestions();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(modulesControllerProvider);
    final state = ref.watch(questionControllerProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final availableModules = _getAllModules(modulesAsync.valueOrNull);

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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildTopicDropdown(modules: availableModules),
                ),
                if (_isTopicMenuOpen)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                  ),
                Expanded(
                  child: state.isLoadingQuestions
                      ? const Center(
                          child: CircularProgressIndicator(color: _primaryPurple),
                        )
                      : state.questions.isEmpty
                          ? const _EmptyHistoryView()
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(questionControllerProvider.notifier)
                                  .loadQuestions(moduleId: _selectedModuleId),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemBuilder: (context, index) {
                                  final item = state.questions[index];
                                  return QuestionHistoryCard(item: item);
                                },
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemCount: state.questions.length,
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicDropdown({required List<ModuleItem> modules}) {
    final selectedModule =
        modules.where((m) => m.id == _selectedModuleId).firstOrNull;
    final selectedTitle = selectedModule?.title ?? 'Tum konular';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _isTopicMenuOpen = !_isTopicMenuOpen),
          child: InputDecorator(
            isFocused: _isTopicMenuOpen,
            decoration: InputDecoration(
              labelText: 'Konu',
              labelStyle: TextStyle(
                color: _primaryPurple.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _softPurple.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _softPurple.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _primaryPurple,
                  width: 1.4,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _isTopicMenuOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _primaryPurple,
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: !_isTopicMenuOpen
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _softPurple.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: modules.length + 1,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: _softPurple.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedModuleId == null;
                        return _buildDropdownOption(
                          title: 'Tum konular',
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedModuleId = null;
                              _isTopicMenuOpen = false;
                            });
                            ref
                                .read(questionControllerProvider.notifier)
                                .loadQuestions();
                          },
                        );
                      }
                      final module = modules[index - 1];
                      final isSelected = module.id == _selectedModuleId;
                      return _buildDropdownOption(
                        title: module.title,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedModuleId = module.id;
                            _isTopicMenuOpen = false;
                          });
                          ref
                              .read(questionControllerProvider.notifier)
                              .loadQuestions(moduleId: module.id);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDropdownOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        color: isSelected
            ? _mediumPurple.withValues(alpha: 0.35)
            : Colors.transparent,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF1A1A2E),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<ModuleItem> _getAllModules(List<ModuleItem>? modules) {
    if (modules == null || modules.isEmpty) return const [];
    final list = [...modules];
    list.sort((a, b) {
      if (a.weekNumber != b.weekNumber) {
        return a.weekNumber.compareTo(b.weekNumber);
      }
      return a.id.compareTo(b.id);
    });
    return list;
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
