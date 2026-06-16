import 'dart:async';
import 'dart:math' as math;

import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);
const _deepPurple = Color(0xFF8B5CF6);
const _lightPurple = Color(0xFFF3F0FF);
const _mediumPurple = Color(0xFFE0D7FF);

/// Geçici: metin sesli okuma (TTS) kapalı; sesler API’den PDF sayfasına göre gelir.
const kModuleTtsEnabled = false;

bool _pageUsesEmbeddedPdfAsset(ContentPage page) {
  final raw = page.mediaUrl?.trim() ?? '';
  if (raw.isEmpty) return false;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return false;
  final type = page.mediaType?.toLowerCase();
  if (type == 'pdf') return true;
  return raw.toLowerCase().endsWith('.pdf');
}

bool _videoUrlLooksYoutube(String raw) {
  final u = raw.trim().toLowerCase();
  return u.contains('youtube.com') || u.contains('youtu.be');
}

class ModulePage extends ConsumerStatefulWidget {
  const ModulePage({required this.moduleId, super.key});

  final String moduleId;

  @override
  ConsumerState<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends ConsumerState<ModulePage> {
  late final PageController _pageController;
  int _currentPage = 0;

  /// Yerel PDF açıkken alt çubuk bu denetleyiciyle sayfa ilerletir (PdfView kaydırması kapalı).
  PdfController? _bridgedPdfController;

  /// API’den gelen sayfa sesleri (MP3; video_player ile arka planda çalınır).
  VideoPlayerController? _pdfPageAudioController;
  int? _activePdfPageAudioPage;
  String? _activePdfPageAudioUrl;
  int _pdfPageAudioSyncSeq = 0;
  bool _pdfPageAudioPlaying = false;
  bool _pdfPageAudioUserMuted = false;

  void _onBridgedPdfPageChanged() {
    if (!mounted) return;
    _pdfPageAudioUserMuted = false;
    unawaited(_syncPdfPageAudio());
    setState(() {});
  }

  void _setBridgedPdf(PdfController controller) {
    if (_bridgedPdfController == controller) return;
    _bridgedPdfController?.pageListenable.removeListener(_onBridgedPdfPageChanged);
    _bridgedPdfController = controller;
    controller.pageListenable.addListener(_onBridgedPdfPageChanged);
    if (mounted) {
      unawaited(_syncPdfPageAudio());
      setState(() {});
    }
  }

  void _detachBridgedPdf({bool rebuild = false}) {
    _bridgedPdfController?.pageListenable.removeListener(_onBridgedPdfPageChanged);
    _bridgedPdfController = null;
    unawaited(_stopPdfPageAudio());
    if (rebuild && mounted) setState(() {});
  }

  void _clearBridgedPdf() => _detachBridgedPdf();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pdfPageAudioSyncSeq++;
    _detachBridgedPdf();
    unawaited(_stopPdfPageAudio());
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _stopPdfPageAudio() async {
    final controller = _pdfPageAudioController;
    _pdfPageAudioController = null;
    _activePdfPageAudioPage = null;
    _activePdfPageAudioUrl = null;
    _pdfPageAudioPlaying = false;
    if (controller == null) return;
    try {
      await controller.pause();
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  PdfPageAudio? _pdfPageAudioForPage(ModuleContent content, int pdfPage) {
    for (final audio in content.pdfPageAudios) {
      if (audio.pdfPageNumber == pdfPage) return audio;
    }
    return null;
  }

  Future<void> _syncPdfPageAudio({bool force = false}) async {
    final syncSeq = ++_pdfPageAudioSyncSeq;
    final ctrl = _bridgedPdfController;
    if (ctrl == null) return;
    if (ctrl.loadingState.value != PdfLoadingState.success) return;

    if (_pdfPageAudioUserMuted && !force) return;

    final content = ref.read(moduleContentProvider(widget.moduleId)).valueOrNull;
    if (content == null || content.pdfPageAudios.isEmpty) {
      await _stopPdfPageAudio();
      return;
    }

    final pdfPage = ctrl.page;
    final target = _pdfPageAudioForPage(content, pdfPage);
    if (target == null) {
      await _stopPdfPageAudio();
      return;
    }

    if (_activePdfPageAudioPage == pdfPage &&
        _activePdfPageAudioUrl == target.audioUrl &&
        _pdfPageAudioController?.value.isPlaying == true) {
      return;
    }

    await _stopPdfPageAudio();
    if (!mounted || syncSeq != _pdfPageAudioSyncSeq) return;

    final player = VideoPlayerController.networkUrl(Uri.parse(target.audioUrl));
    _pdfPageAudioController = player;
    _activePdfPageAudioPage = pdfPage;
    _activePdfPageAudioUrl = target.audioUrl;

    try {
      await player.initialize();
      if (!mounted ||
          syncSeq != _pdfPageAudioSyncSeq ||
          _pdfPageAudioController != player) {
        await player.dispose();
        return;
      }
      await player.setVolume(1);
      await player.play();
      if (!mounted ||
          syncSeq != _pdfPageAudioSyncSeq ||
          _pdfPageAudioController != player) {
        return;
      }
      _pdfPageAudioPlaying = true;
      if (mounted) setState(() {});
      if (kDebugMode) {
        debugPrint(
          '[PdfPageAudio] Sayfa $pdfPage sesi çalıyor: ${target.title ?? target.audioUrl}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[PdfPageAudio] Yüklenemedi (sayfa $pdfPage): $error');
      }
      if (_pdfPageAudioController == player) {
        await _stopPdfPageAudio();
      } else {
        try {
          await player.dispose();
        } catch (_) {}
      }
      if (mounted && syncSeq == _pdfPageAudioSyncSeq) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sayfa $pdfPage sesi yüklenemedi.',
              style: const TextStyle(fontSize: 14),
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _darkPurple.withValues(alpha: 0.95),
          ),
        );
      }
    }
  }

  Future<void> _togglePdfPageAudio() async {
    if (_pdfPageAudioPlaying) {
      _pdfPageAudioUserMuted = true;
      _pdfPageAudioSyncSeq++;
      await _stopPdfPageAudio();
      if (mounted) setState(() {});
      return;
    }

    _pdfPageAudioUserMuted = false;
    await _syncPdfPageAudio(force: true);
    if (mounted) setState(() {});
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
            clipBehavior: Clip.none,
            physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (page) {
              _pdfPageAudioSyncSeq++;
              _pdfPageAudioUserMuted = false;
              unawaited(_stopPdfPageAudio());
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
              final showPdfAudioControl =
                  _pageUsesEmbeddedPdfAsset(contentPage) &&
                  content.pdfPageAudios.isNotEmpty;
              return _ContentPageView(
                page: contentPage,
                showPdfPageAudioControl: showPdfAudioControl,
                isPdfPageAudioPlaying: _pdfPageAudioPlaying,
                isPdfPageAudioMuted: _pdfPageAudioUserMuted,
                onPdfPageAudioToggle: _togglePdfPageAudio,
                onPdfBridgeAttach: _setBridgedPdf,
                onPdfBridgeDetach: _clearBridgedPdf,
              );
            },
          ),
        ),
        _buildBottomNavigation(context, content, hasVideo, totalPages),
      ],
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    ModuleContent content,
    bool hasVideo,
    int totalPages,
  ) {
    final isVideoPage = hasVideo && _currentPage == totalPages - 1;
    final onContentPage =
        !isVideoPage && _currentPage < content.contentPages.length;
    final currentContentPage =
        onContentPage ? content.contentPages[_currentPage] : null;
    final isEmbeddedPdf = currentContentPage != null &&
        _pageUsesEmbeddedPdfAsset(currentContentPage);

    VoidCallback? onPrevious;
    VoidCallback? onNext;
    var nextEnabled = true;
    var previousEnabled = true;
    String? centerLabel;
    var previousLabel = 'Önceki';
    var nextLabel = 'Sonraki';

    if (isVideoPage) {
      onPrevious =
          _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null;
      onNext = null;
    } else if (isEmbeddedPdf) {
      final ctrl = _bridgedPdfController;
      final loaded = ctrl != null &&
          ctrl.loadingState.value == PdfLoadingState.success &&
          (ctrl.pagesCount ?? 0) >= 1;
      final totalPdf = loaded ? (ctrl.pagesCount ?? 0) : 0;
      final currentPdf = loaded ? ctrl.page : 1;

      if (!loaded) {
        onPrevious =
            _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null;
        previousEnabled = onPrevious != null;
        onNext = () {};
        nextEnabled = false;
        centerLabel = 'PDF yükleniyor…';
      } else {
        if (totalPdf > 1) {
          centerLabel = 'Sayfa $currentPdf / $totalPdf';
        }

        if (currentPdf > 1) {
          final c = ctrl;
          onPrevious = () {
            c.previousPage(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            );
          };
          previousLabel = 'Önceki sayfa';
        } else if (_currentPage > 0) {
          onPrevious = () => _goToPage(_currentPage - 1);
        } else {
          onPrevious = null;
        }

        final hasOuterNext = _currentPage < totalPages - 1;
        if (currentPdf < totalPdf) {
          final c = ctrl;
          onNext = () {
            c.nextPage(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            );
          };
          nextLabel = 'Sonraki sayfa';
        } else if (hasOuterNext) {
          onNext = () => _goToPage(_currentPage + 1);
          final nextIsVideo = hasVideo && _currentPage + 1 == totalPages - 1;
          nextLabel = nextIsVideo ? 'Videoya geç' : 'Sonraki';
        } else {
          onNext = null;
        }
      }
    } else {
      onPrevious =
          _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null;
      onNext = _currentPage < totalPages - 1
          ? () => _goToPage(_currentPage + 1)
          : null;
    }

    return _BottomNavigation(
      currentPage: _currentPage,
      totalPages: totalPages,
      centerLabel: centerLabel,
      previousLabel: previousLabel,
      nextLabel: nextLabel,
      previousEnabled: previousEnabled,
      nextEnabled: nextEnabled,
      onPrevious: onPrevious,
      onNext: onNext,
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
    this.showPdfPageAudioControl = false,
    this.isPdfPageAudioPlaying = false,
    this.isPdfPageAudioMuted = false,
    this.onPdfPageAudioToggle,
    this.onPdfBridgeAttach,
    this.onPdfBridgeDetach,
  });

  static const double _horizontalInset = 20;

  final ContentPage page;
  final bool showPdfPageAudioControl;
  final bool isPdfPageAudioPlaying;
  final bool isPdfPageAudioMuted;
  final VoidCallback? onPdfPageAudioToggle;
  final void Function(PdfController controller)? onPdfBridgeAttach;
  final VoidCallback? onPdfBridgeDetach;

  bool get _isVideoContent {
    final type = page.mediaType?.toLowerCase();
    if (type == 'video') return true;
    final mediaUrl = page.mediaUrl?.toLowerCase() ?? '';
    return mediaUrl.endsWith('.mp4') ||
        mediaUrl.endsWith('.mov') ||
        mediaUrl.endsWith('.m3u8') ||
        mediaUrl.endsWith('.webm');
  }

  bool get _mediaAbove {
    final p = page.mediaPosition.toLowerCase();
    return p == 'above' || p == 'top' || p == 'before';
  }

  bool get _hasMedia =>
      page.mediaUrl != null && page.mediaUrl!.trim().isNotEmpty;

  /// PDF tam ekran genişliğinde; video/görsel layout genişliğinde (yatay inset ile).
  ///
  /// [pdfHeight]: Yerel PDF için sabit görünüm alanı yüksekliği (Expanded ile verilir).
  /// Verilmezse kaydırılabilir sayfa düzeninde kullanılan varsayılan yükseklik kullanılır.
  Widget _mediaBlock(
    BuildContext context, {
    required double width,
    double? pdfHeight,
  }) {
    final url = page.mediaUrl!;
    if (_isVideoContent) {
      return SizedBox(
        width: width,
        child: _InlineNetworkVideo(mediaUrl: url),
      );
    }
    if (_pageUsesEmbeddedPdfAsset(page)) {
      final screenH = MediaQuery.sizeOf(context).height;
      final h = pdfHeight ?? math.min(620.0, screenH * 0.62);
      return SizedBox(
        width: width,
        height: h,
        child: _InlinePdfAsset(
          assetPath: url.trim(),
          width: width,
          height: h,
          useExternalPageNavigation: onPdfBridgeAttach != null,
          onBridgeAttach: onPdfBridgeAttach,
          onBridgeDetach: onPdfBridgeDetach,
          showPageAudioControl: showPdfPageAudioControl,
          isPageAudioPlaying: isPdfPageAudioPlaying,
          isPageAudioMuted: isPdfPageAudioMuted,
          onPageAudioToggle: onPdfPageAudioToggle,
        ),
      );
    }
    return SizedBox(
      width: width,
      child: Image.network(
        url,
        width: width,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: 180,
            child: const Center(
              child: CircularProgressIndicator(color: _primaryPurple),
            ),
          );
        },
        errorBuilder: (_, error, stackTrace) => SizedBox(
          width: width,
          height: 120,
          child: Container(
            color: _lightPurple,
            alignment: Alignment.center,
            child: const Text(
              'Görsel yüklenemedi',
              style: TextStyle(
                color: _darkPurple,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mediaSlot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
      child: LayoutBuilder(
        builder: (ctx, c) => _mediaBlock(ctx, width: c.maxWidth),
      ),
    );
  }

  Widget _pageHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
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
        ],
      ),
    );
  }

  Widget _sectionsScrollColumn({required int flex}) {
    return Expanded(
      flex: flex,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in page.sections) ...[
                _SectionWidget(section: section),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _embeddedPdfExpandedSlot(BuildContext context, {required int flex}) {
    final screenW = MediaQuery.sizeOf(context).width;
    return Expanded(
      flex: flex,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final h = c.maxHeight;
          if (!h.isFinite || h <= 0) {
            return const SizedBox.shrink();
          }
          return _mediaBlock(ctx, width: screenW, pdfHeight: h);
        },
      ),
    );
  }

  /// PdfView dikey sayfa sayfa; dış kaydırıcı ile jest çakışması olmaması için PDF Expanded alanında.
  Widget _buildEmbeddedPdfLayout(BuildContext context) {
    final hasSections = page.sections.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasMedia && _mediaAbove) ...[
            _embeddedPdfExpandedSlot(context, flex: hasSections ? 3 : 1),
            if (hasSections) ...[
              const SizedBox(height: 20),
              _sectionsScrollColumn(flex: 2),
            ],
          ] else ...[
            if (hasSections) _sectionsScrollColumn(flex: 2),
            if (_hasMedia && !_mediaAbove) ...[
              if (hasSections) const SizedBox(height: 20),
              _embeddedPdfExpandedSlot(context, flex: hasSections ? 3 : 1),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pageUsesEmbeddedPdfAsset(page)) {
      return _buildEmbeddedPdfLayout(context);
    }

    return SingleChildScrollView(
      clipBehavior: Clip.none,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeader(context),
          if (_hasMedia && _mediaAbove) ...[
            const SizedBox(height: 20),
            _mediaSlot(context),
            const SizedBox(height: 20),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in page.sections) ...[
                  _SectionWidget(section: section),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          if (_hasMedia && !_mediaAbove) ...[
            _mediaSlot(context),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _InlinePdfAsset extends StatefulWidget {
  const _InlinePdfAsset({
    required this.assetPath,
    required this.width,
    required this.height,
    this.useExternalPageNavigation = false,
    this.onBridgeAttach,
    this.onBridgeDetach,
    this.showPageAudioControl = false,
    this.isPageAudioPlaying = false,
    this.isPageAudioMuted = false,
    this.onPageAudioToggle,
  });

  final String assetPath;
  final double width;
  final double height;
  final bool useExternalPageNavigation;
  final void Function(PdfController controller)? onBridgeAttach;
  final VoidCallback? onBridgeDetach;
  final bool showPageAudioControl;
  final bool isPageAudioPlaying;
  final bool isPageAudioMuted;
  final VoidCallback? onPageAudioToggle;

  @override
  State<_InlinePdfAsset> createState() => _InlinePdfAssetState();
}

class _InlinePdfAssetState extends State<_InlinePdfAsset> {
  late final PdfController _controller;
  bool _didAttachToBridge = false;
  List<PhotoViewController>? _photoControllers;

  void _disposePhotoControllers() {
    if (_photoControllers == null) return;
    for (final c in _photoControllers!) {
      c.dispose();
    }
    _photoControllers = null;
  }

  void _syncPhotoControllersForDocument() {
    final state = _controller.loadingState.value;
    if (state == PdfLoadingState.loading) {
      _disposePhotoControllers();
      return;
    }
    if (state != PdfLoadingState.success) return;
    final n = _controller.pagesCount ?? 0;
    if (n < 1) {
      _disposePhotoControllers();
      return;
    }
    if (_photoControllers != null && _photoControllers!.length == n) return;
    _disposePhotoControllers();
    _photoControllers = List.generate(n, (_) => PhotoViewController());
  }

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: PdfDocument.openAsset(widget.assetPath),
    );
    _controller.loadingState.addListener(_onPdfControllerLoadingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNotifyPdfBridge());
  }

  void _onPdfControllerLoadingChanged() {
    _syncPhotoControllersForDocument();
    if (mounted) setState(() {});
    _tryNotifyPdfBridge();
  }

  void _tryNotifyPdfBridge() {
    if (!widget.useExternalPageNavigation) return;
    if (_didAttachToBridge) return;
    if (_controller.loadingState.value != PdfLoadingState.success) return;
    final n = _controller.pagesCount;
    if (n == null || n < 1) return;
    _didAttachToBridge = true;
    widget.onBridgeAttach?.call(_controller);
  }

  @override
  void dispose() {
    if (_didAttachToBridge) {
      widget.onBridgeDetach?.call();
    }
    _controller.loadingState.removeListener(_onPdfControllerLoadingChanged);
    _disposePhotoControllers();
    _controller.dispose();
    super.dispose();
  }

  PhotoViewGalleryPageOptions _buildPdfPageGalleryOption(
    BuildContext context,
    Future<PdfPageImage> pageImage,
    int index,
    PdfDocument document,
  ) {
    final ctrls = _photoControllers;
    if (ctrls == null || index < 0 || index >= ctrls.length) {
      return PhotoViewGalleryPageOptions(
        imageProvider: PdfPageImageProvider(
          pageImage,
          index,
          document.id,
        ),
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.contained * 5.0,
        initialScale: PhotoViewComputedScale.covered * 1.0,
        heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
      );
    }
    return PhotoViewGalleryPageOptions(
      imageProvider: PdfPageImageProvider(
        pageImage,
        index,
        document.id,
      ),
      controller: ctrls[index],
      minScale: PhotoViewComputedScale.contained * 1.0,
      maxScale: PhotoViewComputedScale.contained * 5.0,
      initialScale: PhotoViewComputedScale.covered * 1.0,
      heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
    );
  }

  void _zoomInCurrentPdfPage() {
    if (_controller.loadingState.value != PdfLoadingState.success) return;
    final ctrls = _photoControllers;
    final n = _controller.pagesCount ?? 0;
    if (ctrls == null || n < 1) return;
    final idx = _controller.page - 1;
    if (idx < 0 || idx >= ctrls.length) return;
    final pc = ctrls[idx];
    final cur = pc.scale;
    final next = (cur ?? 1.05) * 1.22;
    pc.scale = next.clamp(0.85, 6.0);
  }

  Future<void> _resetZoomForCurrentPage() async {
    if (_controller.loadingState.value != PdfLoadingState.success) return;
    final ctrls = _photoControllers;
    final n = _controller.pagesCount ?? 0;
    if (ctrls == null || n < 1) return;
    final idx = _controller.page - 1;
    if (idx >= 0 && idx < ctrls.length) {
      ctrls[idx].reset();
    }
    final p = _controller.page.clamp(1, n);
    await _controller.animateToPage(
      p,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final extNav = widget.useExternalPageNavigation;
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: PdfView(
                controller: _controller,
                scrollDirection: Axis.vertical,
                pageSnapping: true,
                physics: extNav
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                backgroundDecoration: const BoxDecoration(color: Colors.white),
                builders: PdfViewBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  pageBuilder: _buildPdfPageGalleryOption,
                  documentLoaderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(color: _primaryPurple),
                  ),
                  pageLoaderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(color: _primaryPurple),
                  ),
                  errorBuilder: (_, error) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'PDF açılamadı',
                      style: TextStyle(
                        color: _darkPurple.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showPageAudioControl && widget.onPageAudioToggle != null)
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.88),
                  elevation: 0,
                  shape: CircleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: IconButton(
                    onPressed: widget.onPageAudioToggle,
                    tooltip: widget.isPageAudioPlaying
                        ? 'Sesi kapat'
                        : 'Sesi aç',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      widget.isPageAudioPlaying
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      size: 22,
                    ),
                    color: widget.isPageAudioPlaying
                        ? _darkPurple
                        : _darkPurple.withValues(alpha: 0.55),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.88),
                elevation: 0,
                shape: CircleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  tooltip: 'Yakınlaştır · uzun bas: sıfırla',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.search_rounded, size: 22),
                  color: _darkPurple,
                  onPressed: _zoomInCurrentPdfPage,
                  onLongPress: () => unawaited(_resetZoomForCurrentPage()),
                ),
              ),
            ),
            if (!extNav)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: ValueListenableBuilder<int>(
                  valueListenable: _controller.pageListenable,
                  builder: (context, currentPage, _) {
                    final total = _controller.pagesCount ?? 0;
                    if (total < 2) return const SizedBox.shrink();
                    return Center(
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withValues(alpha: 0.94),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Önceki sayfa',
                                visualDensity: VisualDensity.compact,
                                onPressed: currentPage > 1
                                    ? () => _controller.previousPage(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        )
                                    : null,
                                icon:
                                    const Icon(Icons.keyboard_arrow_up_rounded),
                                color: _darkPurple,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '$currentPage / $total',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _darkPurple,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Sonraki sayfa',
                                visualDensity: VisualDensity.compact,
                                onPressed: currentPage < total
                                    ? () => _controller.nextPage(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        )
                                    : null,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                color: _darkPurple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ağ videosu: tam alanı doldurur, üstüne ek gölge/overlay koymaz.
class _NetworkVideoPlayer extends StatefulWidget {
  const _NetworkVideoPlayer({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdated);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdated);
    super.dispose();
  }

  void _onControllerUpdated() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    final controller = widget.controller;
    if (!controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final size = controller.value.size;
    final videoWidth = size.width > 0 ? size.width : 16.0;
    final videoHeight = size.height > 0 ? size.height : 9.0;
    final isPlaying = controller.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlayPause,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: videoWidth,
                height: videoHeight,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          if (!isPlaying)
            IconButton.filled(
              onPressed: _togglePlayPause,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                minimumSize: const Size(56, 40),
                fixedSize: const Size(56, 40),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineNetworkVideo extends StatefulWidget {
  const _InlineNetworkVideo({required this.mediaUrl});

  final String mediaUrl;

  @override
  State<_InlineNetworkVideo> createState() => _InlineNetworkVideoState();
}

class _InlineNetworkVideoState extends State<_InlineNetworkVideo> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
    _initializeFuture = _controller.initialize().catchError((_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: _mediumPurple.withValues(alpha: 0.35)),
        ),
        color: _lightPurple,
      ),
      child: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (_hasError || snapshot.hasError) {
            return Container(
              height: 180,
              color: _lightPurple,
              alignment: Alignment.center,
              child: const Text(
                'Video yüklenemedi',
                style: TextStyle(
                  color: _darkPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done ||
              !_controller.value.isInitialized) {
            return const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: _primaryPurple),
              ),
            );
          }

          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0
                ? 16 / 9
                : _controller.value.aspectRatio,
            child: _NetworkVideoPlayer(controller: _controller),
          );
        },
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
        if (section.body.trim().isNotEmpty) ...[
          Text(
            section.body,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
        if (section.keyPoints != null && section.keyPoints!.isNotEmpty) ...[
          if (section.heading != null || section.body.trim().isNotEmpty)
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
        if (section.bodyAfter != null && section.bodyAfter!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            section.bodyAfter!,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF374151),
              height: 1.6,
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
  YoutubePlayerController? _ytController;
  VideoPlayerController? _networkVideoController;
  Future<void>? _networkVideoInitFuture;
  bool _networkVideoError = false;

  static const double _playerAspect = 16 / 9;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl.trim();
    if (url.isEmpty) return;

    if (_videoUrlLooksYoutube(url)) {
      final videoId =
          YoutubePlayerController.convertUrlToId(url) ?? '';
      if (videoId.isEmpty) return;
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
          mute: false,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      _networkVideoController = VideoPlayerController.networkUrl(uri);
      _networkVideoInitFuture =
          _networkVideoController!.initialize().catchError((_) {
        if (!mounted) return;
        setState(() => _networkVideoError = true);
      });
    } catch (_) {
      _networkVideoError = true;
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    _networkVideoController?.dispose();
    super.dispose();
  }

  Widget _videoPlaceholder(double height, String message) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: _lightPurple,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$message\n${widget.videoUrl}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(double playerHeight) {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      return _videoPlaceholder(playerHeight, 'Video adresi eksik.');
    }

    if (_videoUrlLooksYoutube(url)) {
      final videoId =
          YoutubePlayerController.convertUrlToId(url) ?? '';
      if (videoId.isEmpty || _ytController == null) {
        return _videoPlaceholder(
          playerHeight,
          'YouTube bağlantısı çözülemedi.',
        );
      }
      return SizedBox(
        width: double.infinity,
        height: playerHeight,
        child: YoutubePlayer(
          key: ValueKey(videoId),
          controller: _ytController!,
          aspectRatio: _playerAspect,
        ),
      );
    }

    final ctrl = _networkVideoController;
    if (ctrl == null || _networkVideoError) {
      return _videoPlaceholder(playerHeight, 'Video yüklenemedi.');
    }

    return SizedBox(
      width: double.infinity,
      height: playerHeight,
      child: FutureBuilder<void>(
        future: _networkVideoInitFuture,
        builder: (context, snapshot) {
          if (_networkVideoError || snapshot.hasError) {
            return ColoredBox(
              color: _lightPurple,
              child: const Center(
                child: Text(
                  'Video yüklenemedi',
                  style: TextStyle(
                    color: _darkPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done ||
              !ctrl.value.isInitialized) {
            return const ColoredBox(
              color: _lightPurple,
              child: Center(
                child: CircularProgressIndicator(color: _primaryPurple),
              ),
            );
          }

          return _NetworkVideoPlayer(controller: ctrl);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyWidth = constraints.maxWidth - 40;
        final playerHeight =
            bodyWidth > 0 ? bodyWidth / _playerAspect : 200.0;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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
                child: _buildPlayer(playerHeight),
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
      },
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.currentPage,
    required this.totalPages,
    this.centerLabel,
    this.previousLabel = 'Önceki',
    this.nextLabel = 'Sonraki',
    this.previousEnabled = true,
    this.nextEnabled = true,
    this.onPrevious,
    this.onNext,
    this.onComplete,
  });

  final int currentPage;
  final int totalPages;
  final String? centerLabel;
  final String previousLabel;
  final String nextLabel;
  final bool previousEnabled;
  final bool nextEnabled;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Future<void> Function()? onComplete;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final centerText =
        centerLabel ?? '${currentPage + 1} / $totalPages';

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
                onPressed:
                    previousEnabled ? onPrevious : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(previousLabel),
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
              centerText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _darkPurple,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onNext != null)
            Expanded(
              child: FilledButton.icon(
                onPressed: nextEnabled ? onNext : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(nextLabel),
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
