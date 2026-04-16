import 'package:diyalizmobile/core/network/dio_providers.dart';
import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/modules/data/datasources/modules_remote_data_source.dart';
import 'package:diyalizmobile/features/modules/data/repositories/modules_repository_impl.dart';
import 'package:diyalizmobile/features/modules/data/static_module_data.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/domain/repositories/modules_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return _loadModules();
  }

  Future<List<ModuleItem>> _loadModules() async {
    final result = await ref.read(modulesRepositoryProvider).getMyModules();
    return switch (result) {
      ApiSuccess<List<ModuleItem>>(:final data) when data.isNotEmpty => data,
      ApiSuccess<List<ModuleItem>>() => kStaticModules,
      ApiFailure<List<ModuleItem>>() => kStaticModules,
    };
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
