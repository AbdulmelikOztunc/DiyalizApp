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
        title: Text('Hoş geldin, ${authState.user?.fullName ?? ''}'),
        centerTitle: true,
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
                module.isUnlocked ? 'Açık' : 'Kilitli',
              ),
              onTap: module.isUnlocked
                  ? () => context.go('/home/module/${module.id}')
                  : null,
            );
          },
        ),
        error: (_, _) => const Center(
          child: Text('Modüller yüklenemedi'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
