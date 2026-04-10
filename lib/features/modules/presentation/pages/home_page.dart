import 'package:diyalizmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hos geldin ${authState.user?.fullName ?? ''}'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: modulesAsync.when(
        data: (modules) => ListView.separated(
          itemCount: modules.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final module = modules[index];
            return ListTile(
              leading: Icon(
                module.isUnlocked ? Icons.lock_open : Icons.lock,
              ),
              title: Text(module.title),
              subtitle: Text(
                module.isUnlocked ? 'Acik' : 'Kilitli',
              ),
              onTap: module.isUnlocked
                  ? () => context.push('/module/${module.id}')
                  : null,
            );
          },
        ),
        error: (_, _) => const Center(
          child: Text('Moduller yuklenemedi'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/ask'),
              child: const Text('Arastirmaciya Sor'),
            ),
          ),
        ),
      ),
    );
  }
}
