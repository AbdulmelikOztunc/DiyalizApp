class ModuleItem {
  const ModuleItem({
    required this.id,
    required this.title,
    required this.isUnlocked,
    this.description = '',
    this.weekNumber = 0,
  });

  final String id;
  final String title;
  final String description;
  final int weekNumber;
  final bool isUnlocked;
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
  });

  final String title;
  final List<ContentSection> sections;
}

class ContentSection {
  const ContentSection({
    required this.body,
    this.heading,
    this.keyPoints,
  });

  final String? heading;
  final String body;
  final List<String>? keyPoints;
}
