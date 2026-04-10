import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color _borderGreen = Color(0xFF2E7D32);

  TextStyle _serif(BuildContext context, {double fontSize = 15, FontWeight? weight}) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge!.copyWith(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Georgia', 'Noto Serif', 'Times New Roman'],
      fontSize: fontSize,
      height: 1.45,
      fontWeight: weight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final serifBody = _serif(context);
    final serifCaption = _serif(context, fontSize: 14);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Hakkında'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth > 560 ? 520.0 : constraints.maxWidth - 32;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hazırlayanlar',
                      textAlign: TextAlign.center,
                      style: _serif(context, fontSize: 18).copyWith(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Arş. Gör. Yakup DİLBİLİR',
                            style: serifCaption,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Prof. Dr. Mehtap KAVURMACI',
                            style: serifCaption,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderGreen, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        child: Column(
                          children: [
                            Text(
                              "Bu eğitim içeriği 'Yapay Zeka Destekli Mobil Eğitimin Hemodiyaliz Hastalarının Öz Bakım Becerileri Ve Bazı Biyokimyasal Parametreleri Üzerine Etkisi' isimli doktora tez çalışması kapsamında kullanılmak üzere hazırlanmıştır.",
                              textAlign: TextAlign.center,
                              style: serifBody,
                            ),
                            const SizedBox(height: 16),
                            Text.rich(
                              TextSpan(
                                style: serifBody,
                                children: [
                                  const TextSpan(
                                    text:
                                        'Bu tez Atatürk Üniversitesi Bilimsel Araştırma Projeleri Koordinasyon Birimi tarafından ',
                                  ),
                                  TextSpan(
                                    text: '16424',
                                    style: serifBody.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(
                                    text: ' proje numarası ile desteklenmiştir.',
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
