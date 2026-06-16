import 'package:diyalizmobile/core/constants/legal_urls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalNoticeText extends StatefulWidget {
  const LegalNoticeText({super.key});

  @override
  State<LegalNoticeText> createState() => _LegalNoticeTextState();
}

class _LegalNoticeTextState extends State<LegalNoticeText> {
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _kvkkRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(LegalUrls.privacyPolicy);
    _kvkkRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(LegalUrls.kvkkDisclosure);
  }

  @override
  void dispose() {
    _privacyRecognizer.dispose();
    _kvkkRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.75),
      fontSize: 12,
      height: 1.45,
      fontWeight: FontWeight.w500,
    );
    const linkStyle = TextStyle(
      color: Colors.white,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(
            text: 'Kayıt olarak ',
          ),
          TextSpan(
            text: 'Gizlilik Politikası',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          const TextSpan(text: ' ve '),
          TextSpan(
            text: 'KVKK Aydınlatma Metni',
            style: linkStyle,
            recognizer: _kvkkRecognizer,
          ),
          const TextSpan(
            text: ' hükümlerini kabul etmiş sayılırsınız.',
          ),
        ],
      ),
    );
  }
}
