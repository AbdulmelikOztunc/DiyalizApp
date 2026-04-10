import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uygulama Hakkinda')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Bu ekran ikinci asamada Word icerikleri ile doldurulacak.\n'
          'Faz 1 kapsaminda sadece mimari ve yonetim iskeleti kurulmustur.',
        ),
      ),
    );
  }
}
