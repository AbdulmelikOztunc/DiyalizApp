import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);
const _deepPurple = Color(0xFF8B5CF6);
const _lightPurple = Color(0xFFF3F0FF);
const _mediumPurple = Color(0xFFE0D7FF);

class ModulePage extends ConsumerStatefulWidget {
  const ModulePage({
    required this.moduleId,
    super.key,
  });

  final String moduleId;

  @override
  ConsumerState<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends ConsumerState<ModulePage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(moduleContentProvider(widget.moduleId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: contentAsync.when(
        data: (content) {
          if (content == null || content.contentPages.isEmpty) {
            return _buildEmptyState();
          }
          return _buildContent(context, content);
        },
        error: (_, _) => _buildEmptyState(),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryPurple),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'İçerik henüz hazır değil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu modülün içeriği yakında eklenecektir.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ModuleContent content) {
    final totalPages = content.contentPages.length;
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        _ModuleAppBar(
          title: content.title,
          currentPage: _currentPage,
          totalPages: totalPages,
          topPadding: topPadding,
          onBack: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              return _ContentPageView(page: content.contentPages[index]);
            },
          ),
        ),
        _BottomNavigation(
          currentPage: _currentPage,
          totalPages: totalPages,
          onPrevious: _currentPage > 0
              ? () => _goToPage(_currentPage - 1)
              : null,
          onNext: _currentPage < totalPages - 1
              ? () => _goToPage(_currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

class _ModuleAppBar extends StatelessWidget {
  const _ModuleAppBar({
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.topPadding,
    required this.onBack,
  });

  final String title;
  final int currentPage;
  final int totalPages;
  final double topPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 12),
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          _PageIndicator(
            currentPage: currentPage,
            totalPages: totalPages,
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(totalPages, (index) {
          final isActive = index == currentPage;
          final isPast = index < currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalPages - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive || isPast
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ContentPageView extends StatelessWidget {
  const _ContentPageView({required this.page});

  final ContentPage page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: _primaryPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          for (final section in page.sections) ...[
            _SectionWidget(section: section),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({required this.section});

  final ContentSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.heading != null) ...[
          Text(
            section.heading!,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _darkPurple,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          section.body,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF374151),
            height: 1.6,
          ),
        ),
        if (section.keyPoints != null && section.keyPoints!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lightPurple,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _mediumPurple.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < section.keyPoints!.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7, right: 10),
                        decoration: const BoxDecoration(
                          color: _primaryPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          section.keyPoints![i],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onPrevious != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Önceki'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryPurple,
                  side: const BorderSide(color: _mediumPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _darkPurple,
              ),
            ),
          ),
          if (onNext != null)
            Expanded(
              child: FilledButton.icon(
                onPressed: onNext,
                icon: const Text('Sonraki'),
                label: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else if (currentPage == totalPages - 1)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Tamamla'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}
