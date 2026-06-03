import 'package:diyalizmobile/core/network/dio_providers.dart';
import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:diyalizmobile/features/modules/data/datasources/modules_remote_data_source.dart';
import 'package:diyalizmobile/features/modules/data/repositories/modules_repository_impl.dart';
import 'package:diyalizmobile/features/modules/data/static_module_data.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/domain/repositories/modules_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String? _pickNonEmptyUrl(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

bool _contentPageIsAudio(ContentPage page) {
  final type = page.mediaType?.toLowerCase();
  if (type == 'audio' || type == 'ses' || type == 'sound') return true;
  final url = page.mediaUrl?.toLowerCase() ?? '';
  return url.endsWith('.mp3') ||
      url.endsWith('.wav') ||
      url.endsWith('.m4a') ||
      url.endsWith('.aac') ||
      url.endsWith('.ogg');
}

bool _contentPageIsVideo(ContentPage page) {
  final type = page.mediaType?.toLowerCase();
  if (type == 'video') return true;
  if (_contentPageIsAudio(page)) return false;
  final mediaUrl = page.mediaUrl?.toLowerCase() ?? '';
  return mediaUrl.endsWith('.mp4') ||
      mediaUrl.endsWith('.mov') ||
      mediaUrl.endsWith('.m3u8') ||
      mediaUrl.endsWith('.webm') ||
      mediaUrl.contains('youtube.com') ||
      mediaUrl.contains('youtu.be');
}

List<PdfPageAudio> _pdfPageAudiosFromRemote(ModuleContent remote) {
  final audios = <PdfPageAudio>[];
  for (final page in remote.contentPages) {
    if (!_contentPageIsAudio(page)) continue;
    final url = _pickNonEmptyUrl(page.mediaUrl);
    if (url == null) continue;
    final pageNum = page.sortOrder;
    if (pageNum == null || pageNum < 1) continue;
    audios.add(
      PdfPageAudio(
        pdfPageNumber: pageNum,
        audioUrl: url,
        contentId: page.contentId,
        title: page.title,
      ),
    );
  }
  audios.sort((a, b) => a.pdfPageNumber.compareTo(b.pdfPageNumber));
  return audios;
}

/// Önce modül kökü `videoUrl`, yoksa API’nin son video içeriği.
String? _videoUrlFromApiModule(ModuleContent remote) {
  final top = _pickNonEmptyUrl(remote.videoUrl);
  if (top != null) return top;

  final pages = remote.contentPages;
  if (pages.isEmpty) return null;

  for (var i = pages.length - 1; i >= 0; i--) {
    if (!_contentPageIsVideo(pages[i])) continue;
    final url = _pickNonEmptyUrl(pages[i].mediaUrl);
    if (url != null) return url;
  }
  return null;
}

ModuleContent _localPdfModuleMergedWithApi({
  required ModuleContent local,
  required ModuleContent remote,
}) {
  final title = remote.title.trim().isNotEmpty ? remote.title : local.title;
  final videoUrl =
      _videoUrlFromApiModule(remote) ?? _pickNonEmptyUrl(local.videoUrl);
  final pdfPageAudios = _pdfPageAudiosFromRemote(remote);
  if (pdfPageAudios.isNotEmpty && kDebugMode) {
    debugPrint(
      '[ModulesController] Modül ${local.moduleId}: '
      '${pdfPageAudios.length} PDF sayfa sesi API’den alındı '
      '(sayfalar: ${pdfPageAudios.map((a) => a.pdfPageNumber).join(", ")})',
    );
  }
  return ModuleContent(
    moduleId: local.moduleId,
    title: title,
    videoUrl: videoUrl,
    contentPages: local.contentPages,
    pdfPageAudios: pdfPageAudios,
  );
}

final modulesRepositoryProvider = Provider<ModulesRepository>((ref) {
  return ModulesRepositoryImpl(
    ModulesRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final modulesControllerProvider =
    AsyncNotifierProvider<ModulesController, List<ModuleItem>>(
      ModulesController.new,
    );

class ModulesController extends AsyncNotifier<List<ModuleItem>> {
  @override
  Future<List<ModuleItem>> build() async {
    final isAuthenticated = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );

    if (!isAuthenticated) {
      return kStaticModules;
    }

    return _loadModules();
  }

  Future<List<ModuleItem>> _loadModules() async {
    final result = await ref.read(modulesRepositoryProvider).getMyModules();
    switch (result) {
      case ApiSuccess<List<ModuleItem>>(:final data):
        if (data.isEmpty) {
          debugPrint(
            '[ModulesController] API basarili ama modul listesi bos geldi, statik veriye dusuluyor.',
          );
          return kStaticModules;
        }
        return data;
      case ApiFailure<List<ModuleItem>>(:final error):
        debugPrint(
          '[ModulesController] Modul listesi alinamadi (status: ${error.statusCode}, code: ${error.code}, message: ${error.message}). Statik veriye dusuluyor.',
        );
        return kStaticModules;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadModules);
  }

  bool isModuleUnlocked(String moduleId) {
    final modules = state.valueOrNull ?? <ModuleItem>[];
    final module = modules.where((m) => m.id == moduleId).firstOrNull;
    return module?.isUnlocked ?? false;
  }
}

final moduleContentProvider = FutureProvider.family<ModuleContent?, String>((
  ref,
  moduleId,
) async {
  final localPdfModule = kLocalAssetPdfModules[moduleId];
  if (localPdfModule != null) {
    final result = await ref
        .read(modulesRepositoryProvider)
        .getModuleContent(moduleId);
    return switch (result) {
      ApiSuccess<ModuleContent>(:final data) =>
        _localPdfModuleMergedWithApi(local: localPdfModule, remote: data),
      ApiFailure<ModuleContent>() => localPdfModule,
    };
  }

  final result = await ref
      .read(modulesRepositoryProvider)
      .getModuleContent(moduleId);

  return switch (result) {
    ApiSuccess<ModuleContent>(:final data) when data.contentPages.isNotEmpty =>
      data,
    ApiSuccess<ModuleContent>() => null,
    ApiFailure<ModuleContent>() => null,
  };
});

final moduleProgressControllerProvider = Provider<ModuleProgressController>((
  ref,
) {
  return ModuleProgressController(ref);
});

class ModuleProgressController {
  ModuleProgressController(this._ref);

  final Ref _ref;

  Future<void> sendProgress({
    required String moduleId,
    required int pageIndex,
    String? contentId,
  }) async {
    await _ref
        .read(modulesRepositoryProvider)
        .sendProgress(
          moduleId: moduleId,
          pageIndex: pageIndex,
          contentId: contentId,
        );
  }
}
