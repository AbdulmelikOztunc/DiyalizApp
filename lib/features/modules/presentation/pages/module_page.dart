import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModulePage extends ConsumerWidget {
  const ModulePage({
    required this.moduleId,
    super.key,
  });

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(moduleContentProvider(moduleId));
    return Scaffold(
      appBar: AppBar(
        title: Text('Modul $moduleId'),
        centerTitle: true,
      ),
      body: contentAsync.when(
        data: (content) {
          if (content == null) {
            return const Center(child: Text('Icerik bulunamadi'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Sayfalar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final page in content.pages) ...[
                Card(child: ListTile(title: Text(page))),
                const SizedBox(height: 8),
              ],
              if (content.videoUrl != null) ...[
                const SizedBox(height: 16),
                Text('Video URL: ${content.videoUrl}'),
              ],
            ],
          );
        },
        error: (_, _) => const Center(
          child: Text('Icerik yuklenemedi'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
