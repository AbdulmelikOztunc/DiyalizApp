import 'dart:async';

import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);
const _deepPurple = Color(0xFF8B5CF6);
const _lightPurple = Color(0xFFF3F0FF);
const _mediumPurple = Color(0xFFE0D7FF);

class ModulePage extends ConsumerStatefulWidget {
  const ModulePage({required this.moduleId, super.key});

  final String moduleId;

  @override
  ConsumerState<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends ConsumerState<ModulePage> {
  late final PageController _pageController;
  late final FlutterTts _tts;
  int _currentPage = 0;
  bool _isSpeaking = false;
  String? _speakingContentId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tts = FlutterTts()
      ..setStartHandler(() {
        if (!mounted) return;
        setState(() => _isSpeaking = true);
      })
      ..setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _isSpeaking = false;
          _speakingContentId = null;
        });
      })
      ..setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _isSpeaking = false;
          _speakingContentId = null;
        });
      })
      ..setErrorHandler((_) {
        if (!mounted) return;
        setState(() {
          _isSpeaking = false;
          _speakingContentId = null;
        });
      });
    unawaited(_configureTts());
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  String _buildNarrationText(ContentPage page) {
    final buffer = StringBuffer(page.title);
    for (final section in page.sections) {
      final heading = section.heading;
      if (heading != null && heading.isNotEmpty) {
        buffer
          ..write('. ')
          ..write(heading);
      }

      if (section.body.isNotEmpty) {
        buffer
          ..write('. ')
          ..write(section.body);
      }

      final points = section.keyPoints;
      if (points != null && points.isNotEmpty) {
        for (final point in points) {
          buffer
            ..write('. ')
            ..write(point);
        }
      }
    }
    return buffer.toString();
  }

  Future<void> _togglePageNarration(ContentPage page) async {
    if (_isSpeaking && _speakingContentId == page.contentId) {
      await _tts.stop();
      return;
    }

    final text = _buildNarrationText(page);
    if (text.isEmpty) return;

    await _tts.stop();
    setState(() => _speakingContentId = page.contentId);
    await _tts.speak(text);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _sendProgress({
    required int pageIndex,
    required ModuleContent content,
  }) async {
    if (pageIndex < 0 || pageIndex >= content.contentPages.length) {
      return;
    }
    final page = content.contentPages[pageIndex];
    try {
      await ref
          .read(moduleProgressControllerProvider)
          .sendProgress(
            moduleId: widget.moduleId,
            pageIndex: pageIndex,
            contentId: page.contentId,
          );
    } catch (_) {
      // Progress errors should not block UI interactions.
    }
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
    final hasVideo = content.videoUrl != null && content.videoUrl!.isNotEmpty;
    final totalPages = content.contentPages.length + (hasVideo ? 1 : 0);
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
            onPageChanged: (page) {
              unawaited(_tts.stop());
              if (page > _currentPage) {
                _sendProgress(pageIndex: _currentPage, content: content);
              }
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, index) {
              if (hasVideo && index == totalPages - 1) {
                return _VideoPageView(videoUrl: content.videoUrl!);
              }
              final contentPage = content.contentPages[index];
              return _ContentPageView(
                page: contentPage,
                isReading:
                    _isSpeaking && _speakingContentId == contentPage.contentId,
                onToggleRead: () => _togglePageNarration(contentPage),
              );
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
          onComplete: () async {
            final lastContentPageIndex = content.contentPages.length - 1;
            if (lastContentPageIndex >= 0) {
              await _sendProgress(
                pageIndex: lastContentPageIndex,
                content: content,
              );
            }
            ref.invalidate(modulesControllerProvider);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
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
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
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
          _PageIndicator(currentPage: currentPage, totalPages: totalPages),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.totalPages});

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
  const _ContentPageView({
    required this.page,
    required this.isReading,
    required this.onToggleRead,
  });

  final ContentPage page;
  final bool isReading;
  final VoidCallback onToggleRead;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onToggleRead,
                icon: Icon(
                  isReading ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 20,
                ),
                tooltip: isReading ? 'Sesli okumayı durdur' : 'Sesli oku',
                style: IconButton.styleFrom(
                  foregroundColor: _darkPurple,
                  backgroundColor: _lightPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isReading
                ? 'Sesli okunuyor...'
                : 'İçeriği sesli dinlemek için butona basın',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
              border: Border.all(color: _mediumPurple.withValues(alpha: 0.6)),
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

class _VideoPageView extends StatefulWidget {
  const _VideoPageView({required this.videoUrl});

  final String videoUrl;

  @override
  State<_VideoPageView> createState() => _VideoPageViewState();
}

class _VideoPageViewState extends State<_VideoPageView> {
  late final YoutubePlayerController _ytController;

  @override
  void initState() {
    super.initState();
    final videoId =
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eğitim Videosu',
            style: TextStyle(
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
          const SizedBox(height: 12),
          const Text(
            'Modülü tamamlamadan önce aşağıdaki eğitim videosunu izleyin.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPurple.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: YoutubePlayer(
                controller: _ytController,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lightPurple,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _mediumPurple.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _mediumPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: _primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Videoyu izledikten sonra "Tamamla" butonuna basarak modülü bitirebilirsiniz.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.4,
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
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
    this.onComplete,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Future<void> Function()? onComplete;

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
                onPressed: onComplete == null
                    ? () => Navigator.of(context).pop()
                    : () async => onComplete!.call(),
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
