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

/// Önce modül kökü `videoUrl`, yoksa API’nin son içerik kaydı (birinci modülde video genelde burada).
String? _videoUrlFromApiModule(ModuleContent remote) {
  final top = _pickNonEmptyUrl(remote.videoUrl);
  if (top != null) return top;

  final pages = remote.contentPages;
  if (pages.isEmpty) return null;

  final lastUrl = _pickNonEmptyUrl(pages.last.mediaUrl);
  if (lastUrl != null) return lastUrl;

  // Son kayıtta medya yoksa geriye doğru ilk dolu medya URL’si (yedek).
  for (var i = pages.length - 2; i >= 0; i--) {
    final url = _pickNonEmptyUrl(pages[i].mediaUrl);
    if (url != null) return url;
  }
  return null;
}

ModuleContent _module1MergedWithApi(ModuleContent remote) {
  final title =
      remote.title.trim().isNotEmpty ? remote.title : kModule1Content.title;
  final videoUrl =
      _videoUrlFromApiModule(remote) ?? _pickNonEmptyUrl(kModule1Content.videoUrl);
  return ModuleContent(
    moduleId: '1',
    title: title,
    videoUrl: videoUrl,
    contentPages: kModule1Content.contentPages,
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
  if (moduleId == '1') {
    final result = await ref
        .read(modulesRepositoryProvider)
        .getModuleContent(moduleId);
    return switch (result) {
      ApiSuccess<ModuleContent>(:final data) => _module1MergedWithApi(data),
      ApiFailure<ModuleContent>() => kModule1Content,
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
