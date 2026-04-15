import 'package:diyalizmobile/features/question/presentation/controllers/question_controller.dart';
import 'package:diyalizmobile/features/question/presentation/pages/question_history_page.dart';
import 'package:diyalizmobile/features/question/presentation/widgets/question_history_card.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);
const _deepPurple = Color(0xFF8B5CF6);
const _mediumPurple = Color(0xFFE0D7FF);
const _softPurple = Color(0xFFB0A8E3);

class QuestionPage extends ConsumerStatefulWidget {
  const QuestionPage({super.key});

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<QuestionPage> {
  final _controller = TextEditingController();
  String? _selectedModuleId;
  bool _isTopicMenuOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend(String? selectedModuleId) {
    final text = _controller.text.trim();
    final moduleId = selectedModuleId ?? _selectedModuleId;
    if (text.isEmpty || moduleId == null) return;
    ref.read(questionControllerProvider.notifier).sendQuestion(
          message: text,
          moduleId: moduleId,
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionControllerProvider);
    final modulesAsync = ref.watch(modulesControllerProvider);
    final recentHistory = state.questions.take(3).toList();
    final availableModules = _getAvailableModules(modulesAsync.valueOrNull);
    final effectiveModuleId = _resolveSelectedModuleId(availableModules);

    ref.listen(questionControllerProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }
    });

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: Column(
        children: [
          _buildHeader(topPadding),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildQuestionCard(
                  state: state,
                  modules: availableModules,
                  selectedModuleId: effectiveModuleId,
                ),
                const SizedBox(height: 24),
                _buildHistoryHeader(),
                const SizedBox(height: 12),
                if (state.isLoadingQuestions)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: _primaryPurple),
                    ),
                  )
                else if (recentHistory.isEmpty)
                  const _EmptyHistoryPreview()
                else
                  for (int i = 0; i < recentHistory.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    QuestionHistoryCard(item: recentHistory[i]),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_deepPurple, _darkPurple, _primaryPurple],
          stops: [0, 0.45, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x337C3AED),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Araştırmacıya Sor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Merak ettiğiniz konuları araştırmacınıza sorun',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required QuestionState state,
    required List<ModuleItem> modules,
    required String? selectedModuleId,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _mediumPurple.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _mediumPurple.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: _primaryPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Sorunuzu Yazın',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Sorunuzu buraya yazın...',
              hintStyle: TextStyle(
                color: _primaryPurple.withValues(alpha: 0.45),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF6F3FF),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _softPurple.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _softPurple.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _primaryPurple,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (modules.isNotEmpty) ...[
            _buildTopicDropdown(
              modules: modules,
              selectedModuleId: selectedModuleId,
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isSending || selectedModuleId == null
                  ? null
                  : () => _handleSend(selectedModuleId),
              icon: state.isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(state.isSending ? 'Gönderiliyor...' : 'Gönder'),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _mediumPurple.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: _primaryPurple,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Son Soru-Cevaplar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: _primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const QuestionHistoryPage(),
              ),
            );
          },
          icon: const Text(
            'Tümünü Gör',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          label: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
        ),
      ],
    );
  }

  Widget _buildTopicDropdown({
    required List<ModuleItem> modules,
    required String? selectedModuleId,
  }) {
    final selectedModule = modules.where((m) => m.id == selectedModuleId).firstOrNull;
    final selectedTitle = selectedModule?.title ?? 'Konu secin';

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
              fillColor: const Color(0xFFF6F3FF),
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
                    itemCount: modules.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: _softPurple.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      final isSelected = module.id == selectedModuleId;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedModuleId = module.id;
                            _isTopicMenuOpen = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          color: isSelected
                              ? _mediumPurple.withValues(alpha: 0.35)
                              : Colors.transparent,
                          child: Text(
                            module.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF1A1A2E),
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<ModuleItem> _getAvailableModules(List<ModuleItem>? modules) {
    if (modules == null || modules.isEmpty) return const [];
    final allModules = [...modules];
    allModules.sort((a, b) {
      if (a.weekNumber != b.weekNumber) {
        return a.weekNumber.compareTo(b.weekNumber);
      }
      return a.id.compareTo(b.id);
    });
    return allModules;
  }

  String? _resolveSelectedModuleId(List<ModuleItem> modules) {
    if (modules.isEmpty) return null;
    if (_selectedModuleId != null &&
        modules.any((module) => module.id == _selectedModuleId)) {
      return _selectedModuleId;
    }
    return modules.first.id;
  }
}

class _EmptyHistoryPreview extends StatelessWidget {
  const _EmptyHistoryPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mediumPurple.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _mediumPurple.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: _primaryPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz soru yok',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sorduğunuz sorular burada cevaplarıyla listelenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _primaryPurple.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
