class ModuleItem {
  const ModuleItem({
    required this.id,
    required this.title,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final bool isUnlocked;
}

class ModuleContent {
  const ModuleContent({
    required this.moduleId,
    required this.pages,
    required this.videoUrl,
  });

  final String moduleId;
  final List<String> pages;
  final String? videoUrl;
}
