import 'package:diyalizmobile/core/settings/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const Color _borderGreen = Color(0xFF2E7D32);

  /// API veya ağ hatası durumunda gösterilir; sunucudaki varsayılan metinle uyumludur.
  static const String _kFallbackAboutText =
      'Bu uygulama, hemodiyaliz hastalarının öz bakım becerilerini geliştirmek, '
      'tedaviye uyumlarını artırmak ve komplikasyonları azaltmak amacıyla Atatürk '
      'Üniversitesi bünyesinde geliştirilmiştir.\n\n'
      'Hazırlayanlar:\n'
      'Arş. Gör. Yakup DİLBİLİR\n'
      'Prof. Dr. Mehtap KAVURMACI\n'
      'Proje No: 16424';

  TextStyle _serif(
    BuildContext context, {
    double fontSize = 15,
    FontWeight? weight,
  }) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge!.copyWith(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Georgia', 'Noto Serif', 'Times New Roman'],
      fontSize: fontSize,
      height: 1.45,
      fontWeight: weight,
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(appSettingsProvider);
    try {
      await ref.read(appSettingsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Hakkında'),
      ),
      body: switch (async) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError() => _aboutBody(
            context,
            ref,
            text: _kFallbackAboutText,
            stale: true,
          ),
        AsyncData(:final value) => _aboutBody(
            context,
            ref,
            text: value.aboutText.isNotEmpty ? value.aboutText : _kFallbackAboutText,
            stale: value.aboutText.isEmpty,
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _aboutBody(
    BuildContext context,
    WidgetRef ref, {
    required String text,
    bool stale = false,
  }) {
    final serifBody = _serif(context);
    final serifCaption = _serif(context, fontSize: 14);
    final parsed = _parseAboutText(text);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth > 560 ? 520.0 : constraints.maxWidth - 32;
        return RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (stale)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Güncel metin yüklenemedi; yerel metin gösteriliyor. '
                          'Yenilemek için aşağı çekin.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                    if (parsed.preparers.isNotEmpty) ...[
                      Text(
                        'Hazırlayanlar',
                        textAlign: TextAlign.center,
                        style: _serif(context, fontSize: 18).copyWith(
                          decoration: TextDecoration.underline,
                          decorationThickness: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPreparers(parsed.preparers, serifCaption),
                      const SizedBox(height: 16),
                    ],
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderGreen, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        child: Text(
                          parsed.bodyText,
                          textAlign: TextAlign.center,
                          style: serifBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _AboutContent _parseAboutText(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').trim();
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final preparersIndex = lines.indexWhere((line) {
      final lower = line.toLowerCase();
      return lower == 'hazırlayanlar:' ||
          lower == 'hazırlayanlar' ||
          lower == 'hazirlayanlar:' ||
          lower == 'hazirlayanlar';
    });

    if (preparersIndex == -1) {
      return _AboutContent(bodyText: normalized, preparers: const []);
    }

    final beforePreparers = lines.take(preparersIndex).toList();
    final afterPreparers = lines.skip(preparersIndex + 1);

    final preparers = <String>[];
    String? projectLine;
    for (final line in afterPreparers) {
      final lower = line.toLowerCase();
      if (lower.startsWith('proje no')) {
        projectLine = line;
      } else {
        preparers.add(line);
      }
    }

    final bodyParts = <String>[];
    if (beforePreparers.isNotEmpty) {
      bodyParts.add(beforePreparers.join('\n'));
    }
    if (projectLine != null) {
      bodyParts.add(projectLine);
    }

    return _AboutContent(
      bodyText: bodyParts.isEmpty ? normalized : bodyParts.join('\n\n'),
      preparers: preparers,
    );
  }

  Widget _buildPreparers(List<String> preparers, TextStyle style) {
    if (preparers.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              preparers[0],
              style: style,
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              preparers[1],
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }

    return Column(
      children: preparers
          .map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                name,
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AboutContent {
  const _AboutContent({
    required this.bodyText,
    required this.preparers,
  });

  final String bodyText;
  final List<String> preparers;
}
