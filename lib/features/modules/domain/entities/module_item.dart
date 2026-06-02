class ModuleItem {
  const ModuleItem({
    required this.id,
    required this.title,
    required this.isUnlocked,
    this.description = '',
    this.weekNumber = 0,
    this.iconName = '',
  });

  final String id;
  final String title;
  final String description;
  final int weekNumber;
  final bool isUnlocked;
  final String iconName;
}

class ModuleContent {
  const ModuleContent({
    required this.moduleId,
    required this.title,
    required this.contentPages,
    this.videoUrl,
    @Deprecated('Use contentPages instead') this.pages = const [],
  });

  final String moduleId;
  final String title;
  final List<ContentPage> contentPages;
  final String? videoUrl;
  final List<String> pages;
}

class ContentPage {
  const ContentPage({
    required this.title,
    required this.sections,
    this.contentId,
    this.mediaUrl,
    this.mediaType,
    this.mediaPosition = 'below',

    /// Ekranda gösterilmez; yalnızca sesli okuma için (PDF görüntü vb.).
    this.narrationText,
  });

  final String title;
  final List<ContentSection> sections;
  final String? contentId;
  final String? mediaUrl;
  final String? mediaType;

  /// API: `above` | `below` (ve `top`/`before` → above, `bottom`/`after` → below).
  final String mediaPosition;

  /// Tam metin veya API’den gelen `narration_text` / `tts_text`.
  final String? narrationText;
}

class ContentSection {
  const ContentSection({
    required this.body,
    this.heading,
    this.keyPoints,
    this.bodyAfter,
  });

  final String? heading;
  final String body;
  final List<String>? keyPoints;

  /// Madde kutusunun altında gösterilecek metin (`ul`/`ol` sonrası paragraflar).
  final String? bodyAfter;
}
