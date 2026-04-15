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
    final root = _extractPrimaryMap(data);
    final moduleMap = _extractMap(root['module']) ?? root;
    final pagesRaw = _extractPages(root, moduleMap);

    final contentPages = pagesRaw.map((pageRaw) {
      final page = pageRaw as Map<String, dynamic>;
      final sectionsRaw = _extractSections(page);
      return ContentPage(
        title: _toStringValue(page, const ['title', 'page_title', 'name']),
        sections: sectionsRaw.map((s) {
          final section = s as Map<String, dynamic>;
          final keyPointsRaw = _extractStringList(section, const [
            'keyPoints',
            'key_points',
            'points',
          ]);
          return ContentSection(
            heading: _toNullableStringValue(section, const [
              'heading',
              'subtitle',
              'title',
            ]),
            body: _toStringValue(section, const ['body', 'text', 'content']),
            keyPoints: keyPointsRaw.isEmpty ? null : keyPointsRaw,
          );
        }).toList(),
      );
    }).toList();

    return ApiSuccess(
      ModuleContent(
        moduleId: moduleId,
        title: _toStringValue(moduleMap, const [
          'title',
          'module_title',
          'name',
        ], fallback: _toStringValue(root, const ['title'], fallback: '')),
        contentPages: contentPages,
        videoUrl: _toNullableStringValue(
          moduleMap,
          const ['videoUrl', 'video_url', 'video'],
          fallback: _toNullableStringValue(root, const [
            'videoUrl',
            'video_url',
            'video',
          ]),
        ),
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
      final idValue = item['id'];
      final weekValue = item['weekNumber'] ?? item['sort_order'];
      final unlockedValue = item['isUnlocked'] ?? item['is_unlocked'];
      return ModuleItem(
        id: idValue?.toString() ?? '',
        title: item['title'] as String? ?? 'Modul',
        description: item['description'] as String? ?? '',
        weekNumber: _toInt(weekValue),
        isUnlocked: _toBool(unlockedValue),
        iconName: _toStringValue(item, const ['icon', 'icon_name', 'iconName']),
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  Map<String, dynamic> _extractPrimaryMap(Map<String, dynamic> raw) {
    final dataMap = _extractMap(raw['data']);
    if (dataMap != null) return dataMap;
    return raw;
  }

  List<dynamic> _extractPages(
    Map<String, dynamic> root,
    Map<String, dynamic> moduleMap,
  ) {
    final pagesFromRoot = _extractList(root, const [
      'contentPages',
      'content_pages',
      'pages',
      'contents',
    ]);
    if (pagesFromRoot.isNotEmpty) return pagesFromRoot;
    return _extractList(moduleMap, const [
      'contentPages',
      'content_pages',
      'pages',
      'contents',
    ]);
  }

  List<dynamic> _extractSections(Map<String, dynamic> page) {
    final sections = _extractList(page, const [
      'sections',
      'content_sections',
      'items',
    ]);
    if (sections.isNotEmpty) return sections;
    final content = _toNullableStringValue(page, const [
      'body',
      'text',
      'content',
    ]);
    if (content == null || content.isEmpty) return const <dynamic>[];
    return <dynamic>[
      <String, dynamic>{'body': content},
    ];
  }

  Map<String, dynamic>? _extractMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  List<dynamic> _extractList(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is List<dynamic>) return value;
    }
    return <dynamic>[];
  }

  List<String> _extractStringList(Map<String, dynamic> map, List<String> keys) {
    final values = _extractList(map, keys);
    return values.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  String _toStringValue(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    final value = _toNullableStringValue(map, keys);
    return value ?? fallback;
  }

  String? _toNullableStringValue(
    Map<String, dynamic> map,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
  }
}
