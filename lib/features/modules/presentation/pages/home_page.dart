import 'package:diyalizmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _primaryPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);
const _deepPurple = Color(0xFF8B5CF6);
const _mediumPurple = Color(0xFFE0D7FF);
const _lockedGrey = Color(0xFFBDBDBD);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: modulesAsync.when(
        data: (modules) {
          final unlockedCount = modules.where((m) => m.isUnlocked).length;
          return CustomScrollView(
            slivers: [
              _HeaderSliver(
                fullName: authState.user?.fullName ?? '',
                unlockedCount: unlockedCount,
                totalCount: modules.length,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList.separated(
                  itemCount: modules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    return _ModuleCard(
                      module: module,
                      onTap: module.isUnlocked
                          ? () => context.go('/home/module/${module.id}')
                          : null,
                    );
                  },
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
        error: (_, _) => const Center(child: Text('Modüller yüklenemedi')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HeaderSliver extends StatelessWidget {
  const _HeaderSliver({
    required this.fullName,
    required this.unlockedCount,
    required this.totalCount,
  });

  final String fullName;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_deepPurple, _darkPurple, _primaryPurple],
            stops: [0, 0.45, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x337C3AED),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldin,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName.isNotEmpty ? fullName : 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Eğitim İlerlemen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$unlockedCount / $totalCount Modül',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, this.onTap});

  final ModuleItem module;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = module.isUnlocked;
    final icon = _resolveModuleIcon(module);

    return Material(
      color: Colors.white,
      elevation: isUnlocked ? 2 : 0.5,
      shadowColor: isUnlocked
          ? _primaryPurple.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnlocked
              ? _mediumPurple.withValues(alpha: 0.7)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _WeekBadge(
                weekNumber: module.weekNumber,
                isUnlocked: isUnlocked,
                icon: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hafta ${module.weekNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked ? _primaryPurple : _lockedGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Açık',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Kilitli',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                    if (module.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        module.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnlocked
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isUnlocked ? Icons.arrow_forward_ios_rounded : Icons.lock,
                size: isUnlocked ? 18 : 20,
                color: isUnlocked ? _primaryPurple : _lockedGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveModuleIcon(ModuleItem module) {
    final byApiName = _iconFromApiName(module.iconName);
    if (byApiName != null) return byApiName;

    final title = module.title.toLowerCase();
    if (title.contains('böbrek') || title.contains('hemodiyaliz')) {
      return Icons.biotech_rounded;
    }
    if (title.contains('beslenme') || title.contains('sıvı')) {
      return Icons.restaurant_rounded;
    }
    if (title.contains('ilaç')) {
      return Icons.medication_rounded;
    }
    if (title.contains('damar') || title.contains('fistül')) {
      return Icons.healing_rounded;
    }
    if (title.contains('komplikasyon') || title.contains('korunma')) {
      return Icons.shield_rounded;
    }
    if (title.contains('psikososyal') || title.contains('yaşam kalitesi')) {
      return Icons.psychology_rounded;
    }

    return Icons.book_rounded;
  }

  IconData? _iconFromApiName(String rawIconName) {
    final normalized = rawIconName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    switch (normalized) {
      case 'bi-heart-pulse':
      case 'heart-pulse':
      case 'heartbeat':
      case 'heart':
        return Icons.favorite_rounded;
      case 'bi-droplet':
      case 'droplet':
      case 'water':
        return Icons.water_drop_rounded;
      case 'bi-capsule':
      case 'capsule':
      case 'pill':
      case 'medication':
        return Icons.medication_rounded;
      case 'bi-bandaid':
      case 'bandaid':
      case 'healing':
        return Icons.healing_rounded;
      case 'bi-shield-check':
      case 'shield':
      case 'protection':
        return Icons.shield_rounded;
      case 'bi-person-hearts':
      case 'psychology':
      case 'support':
        return Icons.psychology_rounded;
      case 'bi-book':
      case 'book':
        return Icons.book_rounded;
      default:
        return null;
    }
  }
}

class _WeekBadge extends StatelessWidget {
  const _WeekBadge({
    required this.weekNumber,
    required this.isUnlocked,
    required this.icon,
  });

  final int weekNumber;
  final bool isUnlocked;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? const LinearGradient(
                colors: [_deepPurple, _primaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUnlocked ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: _primaryPurple.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: isUnlocked ? Colors.white : _lockedGrey,
        size: 28,
      ),
    );
  }
}
