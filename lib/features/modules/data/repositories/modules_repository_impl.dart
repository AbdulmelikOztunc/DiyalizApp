import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/modules/data/datasources/modules_remote_data_source.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/domain/repositories/modules_repository.dart';

class ModulesRepositoryImpl implements ModulesRepository {
  ModulesRepositoryImpl(this._remoteDataSource);

  final ModulesRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<ModuleContent>> getModuleContent(String moduleId) async {
    final response = await _remoteDataSource.getModuleContent(moduleId);
    if (response case ApiFailure(:final error)) {
      return ApiFailure(error);
    }

    final data = (response as ApiSuccess<Map<String, dynamic>>).data;
    final pagesRaw = data['contentPages'] as List<dynamic>? ?? <dynamic>[];

    final contentPages = pagesRaw.map((pageRaw) {
      final page = pageRaw as Map<String, dynamic>;
      final sectionsRaw = page['sections'] as List<dynamic>? ?? <dynamic>[];
      return ContentPage(
        title: page['title'] as String? ?? '',
        sections: sectionsRaw.map((s) {
          final section = s as Map<String, dynamic>;
          final keyPointsRaw = section['keyPoints'] as List<dynamic>?;
          return ContentSection(
            heading: section['heading'] as String?,
            body: section['body'] as String? ?? '',
            keyPoints: keyPointsRaw?.map((e) => e.toString()).toList(),
          );
        }).toList(),
      );
    }).toList();

    return ApiSuccess(
      ModuleContent(
        moduleId: moduleId,
        title: data['title'] as String? ?? '',
        contentPages: contentPages,
        videoUrl: data['videoUrl'] as String?,
      ),
    );
  }

  @override
  Future<ApiResult<List<ModuleItem>>> getMyModules() async {
    final response = await _remoteDataSource.getMyModules();
    if (response case ApiFailure(:final error)) {
      return ApiFailure(error);
    }

    final data = (response as ApiSuccess<Map<String, dynamic>>).data;
    final modulesRaw = data['modules'] as List<dynamic>? ?? <dynamic>[];
    final modules = modulesRaw.map((raw) {
      final item = raw as Map<String, dynamic>;
      return ModuleItem(
        id: item['id'] as String? ?? '',
        title: item['title'] as String? ?? 'Modul',
        description: item['description'] as String? ?? '',
        weekNumber: item['weekNumber'] as int? ?? 0,
        isUnlocked: item['isUnlocked'] as bool? ?? false,
      );
    }).toList();
    return ApiSuccess(modules);
  }

  @override
  Future<ApiResult<void>> sendProgress({
    required String moduleId,
    required int pageIndex,
  }) async {
    final response = await _remoteDataSource.sendProgress(
      moduleId: moduleId,
      pageIndex: pageIndex,
    );
    if (response case ApiFailure(:final error)) {
      return ApiFailure(error);
    }
    return const ApiSuccess<void>(null);
  }
}
