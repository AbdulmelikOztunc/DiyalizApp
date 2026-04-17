import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/modules/data/datasources/modules_remote_data_source.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/domain/repositories/modules_repository.dart';

class ModulesRepositoryImpl implements ModulesRepository {
  ModulesRepositoryImpl(this._remoteDataSource);

  final ModulesRemoteDataSource _remoteDataSource;
  static const _mediaRootUrl = 'http://diyalizapp.com.tr';

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
    final contentPages = await _mapContentPages(
      moduleId: moduleId,
      pagesRaw: pagesRaw,
    );

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
    String? contentId,
  }) async {
    final response = await _remoteDataSource.sendProgress(
      moduleId: moduleId,
      pageIndex: pageIndex,
      contentId: contentId,
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
      'content_list',
      'module_contents',
    ]);
    if (pagesFromRoot.isNotEmpty) return pagesFromRoot;
    final pagesFromModule = _extractList(moduleMap, const [
      'contentPages',
      'content_pages',
      'pages',
      'contents',
      'content_list',
      'module_contents',
    ]);
    if (pagesFromModule.isNotEmpty) return pagesFromModule;

    final contentFromRoot = _extractMap(root['content']);
    if (contentFromRoot != null) return <dynamic>[contentFromRoot];
    final contentFromModule = _extractMap(moduleMap['content']);
    if (contentFromModule != null) return <dynamic>[contentFromModule];
    return <dynamic>[];
  }

  Future<List<ContentPage>> _mapContentPages({
    required String moduleId,
    required List<dynamic> pagesRaw,
  }) async {
    final pages = <ContentPage>[];
    for (var i = 0; i < pagesRaw.length; i++) {
      final raw = pagesRaw[i];
      if (raw is! Map<String, dynamic>) continue;
      final page = await _mapSinglePage(
        moduleId: moduleId,
        index: i,
        page: raw,
      );
      pages.add(page);
    }
    return pages;
  }

  Future<ContentPage> _mapSinglePage({
    required String moduleId,
    required int index,
    required Map<String, dynamic> page,
  }) async {
    final contentId = _toNullableStringValue(page, const ['id', 'content_id']);
    final title = _toStringValue(page, const [
      'title',
      'page_title',
      'name',
    ], fallback: 'İçerik ${index + 1}');
    final sectionsRaw = _extractSections(page);
    if (sectionsRaw.isNotEmpty) {
      return ContentPage(
        contentId: contentId,
        title: title,
        mediaUrl: _extractMediaUrl(page),
        mediaType: _extractMediaType(page),
        sections: sectionsRaw.map((s) => _mapContentSectionFromRaw(s)).toList(),
      );
    }

    if (contentId != null && contentId.isNotEmpty) {
      final detailResult = await _remoteDataSource.getContentDetail(contentId);
      if (detailResult case ApiSuccess<Map<String, dynamic>>(:final data)) {
        final detailRoot = _extractPrimaryMap(data);
        final detailMap = _extractMap(detailRoot['content']) ?? detailRoot;
        return ContentPage(
          contentId: contentId,
          title: _toStringValue(detailMap, const [
            'title',
            'name',
          ], fallback: title),
          mediaUrl: _extractMediaUrl(detailMap),
          mediaType: _extractMediaType(detailMap),
          sections: _mapSectionsFromDetail(detailMap),
        );
      }
    }

    final fallbackBody = _toStringValue(page, const [
      'body',
      'text',
      'content',
      'description',
    ]);
    return ContentPage(
      contentId: contentId,
      title: title,
      mediaUrl: _extractMediaUrl(page),
      mediaType: _extractMediaType(page),
      sections: fallbackBody.isEmpty
          ? const <ContentSection>[]
          : <ContentSection>[ContentSection(body: fallbackBody)],
    );
  }

  ContentSection _mapContentSectionFromRaw(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return ContentSection(body: raw.toString());
    }
    final section = raw;
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
  }

  List<ContentSection> _mapSectionsFromDetail(Map<String, dynamic> detailMap) {
    final sectionsRaw = _extractSections(detailMap);
    if (sectionsRaw.isNotEmpty) {
      return sectionsRaw.map((s) => _mapContentSectionFromRaw(s)).toList();
    }

    final richText = _toNullableStringValue(detailMap, const [
      'body_text',
      'body',
      'content',
      'description',
    ]);
    if (richText == null || richText.isEmpty) {
      return const <ContentSection>[];
    }
    return _parseSectionsFromRichText(richText);
  }

  List<ContentSection> _parseSectionsFromRichText(String source) {
    final blockRegex = RegExp(
      r'<(h[1-6]|p|ul|ol)[^>]*>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );
    final blocks = blockRegex.allMatches(source).toList();
    if (blocks.isEmpty) {
      final plain = _cleanHtmlText(source);
      if (plain.isEmpty) return const <ContentSection>[];
      return <ContentSection>[ContentSection(body: plain)];
    }

    final sections = <ContentSection>[];
    String? heading;
    final bodyParts = <String>[];
    final points = <String>[];
    var cursor = 0;

    void flush() {
      final body = bodyParts.join('\n\n').trim();
      if ((heading == null || heading!.isEmpty) &&
          body.isEmpty &&
          points.isEmpty) {
        return;
      }
      sections.add(
        ContentSection(
          heading: heading,
          body: body.isEmpty ? ' ' : body,
          keyPoints: points.isEmpty ? null : List<String>.from(points),
        ),
      );
      heading = null;
      bodyParts.clear();
      points.clear();
    }

    void appendPlainText(String rawText) {
      final plain = _cleanHtmlText(rawText);
      if (plain.isNotEmpty) {
        bodyParts.add(plain);
      }
    }

    for (final block in blocks) {
      if (block.start > cursor) {
        appendPlainText(source.substring(cursor, block.start));
      }

      final tag = (block.group(1) ?? '').toLowerCase();
      final inner = block.group(2) ?? '';
      if (tag.startsWith('h')) {
        flush();
        heading = _cleanHtmlText(inner);
        cursor = block.end;
        continue;
      }
      if (tag == 'p') {
        final paragraph = _cleanHtmlText(inner);
        if (paragraph.isNotEmpty) bodyParts.add(paragraph);
        cursor = block.end;
        continue;
      }
      if (tag == 'ul' || tag == 'ol') {
        final liRegex = RegExp(
          r'<li[^>]*>(.*?)</li>',
          caseSensitive: false,
          dotAll: true,
        );
        for (final li in liRegex.allMatches(inner)) {
          final text = _cleanHtmlText(li.group(1) ?? '');
          if (text.isNotEmpty) points.add(text);
        }
        if (points.isEmpty) {
          appendPlainText(inner);
        }
      }
      cursor = block.end;
    }

    if (cursor < source.length) {
      appendPlainText(source.substring(cursor));
    }

    flush();
    return sections
        .where(
          (s) => s.body.trim().isNotEmpty || (s.keyPoints?.isNotEmpty ?? false),
        )
        .toList();
  }

  String _cleanHtmlText(String value) {
    var text = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&Uuml;', 'Ü')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&Ouml;', 'Ö')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&Ccedil;', 'Ç')
        .replaceAll('&scedil;', 'ş')
        .replaceAll('&Scedil;', 'Ş')
        .replaceAll('&iacute;', 'i')
        .replaceAll('&Iacute;', 'İ');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n\s+'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  String? _extractMediaUrl(Map<String, dynamic> map) {
    final raw = _toNullableStringValue(map, const [
      'media_file',
      'mediaUrl',
      'media_url',
      'image',
      'image_url',
    ]);
    if (raw == null || raw.isEmpty) return null;

    final normalized = raw.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return Uri.encodeFull(normalized);
    }
    if (normalized.startsWith('//')) {
      return Uri.encodeFull('http:$normalized');
    }

    final mediaRootUri = Uri.parse(_mediaRootUrl);
    final path = normalized.startsWith('/') ? normalized : '/$normalized';
    return Uri.encodeFull(mediaRootUri.resolve(path).toString());
  }

  String? _extractMediaType(Map<String, dynamic> map) {
    final explicitType = _toNullableStringValue(map, const [
      'content_type',
      'media_type',
      'type',
    ]);
    if (explicitType != null && explicitType.isNotEmpty) {
      return explicitType.toLowerCase();
    }

    final mediaUrl = _extractMediaUrl(map);
    if (mediaUrl == null) return null;
    final uri = Uri.tryParse(mediaUrl);
    final path = (uri?.path ?? mediaUrl).toLowerCase();
    if (path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m3u8') ||
        path.endsWith('.webm')) {
      return 'video';
    }
    if (path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif')) {
      return 'image';
    }
    return null;
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
