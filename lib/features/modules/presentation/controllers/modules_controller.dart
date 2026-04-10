import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/core/network/dio_providers.dart';
import 'package:diyalizmobile/features/modules/data/datasources/modules_remote_data_source.dart';
import 'package:diyalizmobile/features/modules/data/repositories/modules_repository_impl.dart';
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
    return fetchModules();
  }

  Future<List<ModuleItem>> fetchModules() async {
    final result = await ref.read(modulesRepositoryProvider).getMyModules();
    return switch (result) {
      ApiSuccess<List<ModuleItem>>(:final data) => data,
      ApiFailure<List<ModuleItem>>() => <ModuleItem>[],
    };
  }

  bool isModuleUnlocked(String moduleId) {
    final modules = state.valueOrNull ?? <ModuleItem>[];
    final module = modules.where((m) => m.id == moduleId).firstOrNull;
    return module?.isUnlocked ?? false;
  }
}

final moduleContentProvider =
    FutureProvider.family<ModuleContent?, String>((ref, moduleId) async {
  final result =
      await ref.read(modulesRepositoryProvider).getModuleContent(moduleId);
  return switch (result) {
    ApiSuccess<ModuleContent>(:final data) => data,
    ApiFailure<ModuleContent>() => null,
  };
});
