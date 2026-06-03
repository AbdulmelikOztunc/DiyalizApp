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

/// API’den gelen ses dosyası; [pdfPageNumber] PDF’teki 1 tabanlı sayfa numarasıdır.
class PdfPageAudio {
  const PdfPageAudio({
    required this.pdfPageNumber,
    required this.audioUrl,
    this.contentId,
    this.title,
  });

  final int pdfPageNumber;
  final String audioUrl;
  final String? contentId;
  final String? title;
}

class ModuleContent {
  const ModuleContent({
    required this.moduleId,
    required this.title,
    required this.contentPages,
    this.videoUrl,
    this.pdfPageAudios = const [],
    @Deprecated('Use contentPages instead') this.pages = const [],
  });

  final String moduleId;
  final String title;
  final List<ContentPage> contentPages;
  final String? videoUrl;

  /// Yerel PDF sayfalarına API’den eşlenen ses kayıtları (`sort_order` = sayfa no).
  final List<PdfPageAudio> pdfPageAudios;
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
    this.sortOrder,

    /// Ekranda gösterilmez; yalnızca sesli okuma için (PDF görüntü vb.).
    this.narrationText,
  });

  final String title;
  final List<ContentSection> sections;
  final String? contentId;
  final String? mediaUrl;
  final String? mediaType;

  /// API `sort_order` / `sira`; ses türünde PDF sayfa numarası.
  final int? sortOrder;

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
