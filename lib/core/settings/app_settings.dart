class AppSettings {
  const AppSettings({
    required this.appName,
    required this.contactEmail,
    required this.moduleUnlockDays,
    required this.aboutText,
  });

  final String appName;
  final String contactEmail;
  final int moduleUnlockDays;
  final String aboutText;

  /// Beklenen gövde: `{ "success": true, "settings": { ... } }`
  factory AppSettings.fromResponse(Map<String, dynamic> root) {
    final map = root['settings'] as Map<String, dynamic>? ?? {};
    return AppSettings(
      appName: map['app_name'] as String? ?? '',
      contactEmail: map['contact_email'] as String? ?? '',
      moduleUnlockDays: (map['module_unlock_days'] as num?)?.toInt() ?? 7,
      aboutText: (map['about_text'] as String? ?? '').trim(),
    );
  }
}
