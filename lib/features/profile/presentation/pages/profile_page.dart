import 'dart:ui';

import 'package:diyalizmobile/features/auth/presentation/utils/tr_national_phone_input_formatter.dart';
import 'package:diyalizmobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _lightPurple = Color(0xFFF3F0FF);
const _mediumPurple = Color(0xFFE0D7FF);
const _accentPurple = Color(0xFF7C3AED);
const _darkPurple = Color(0xFF5B21B6);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneAsync = ref.watch(cachedPhoneProvider);
    final emailAsync = ref.watch(cachedEmailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _UserHeader(
            phone: phoneAsync.valueOrNull,
            email: emailAsync.valueOrNull,
          ),
          const SizedBox(height: 24),
          _MenuCard(
            icon: Icons.email_outlined,
            title: 'Email Güncelle',
            subtitle: emailAsync.when(
              data: (email) => email != null && email.isNotEmpty
                  ? email
                  : 'Email adresi kayıtlı değil',
              loading: () => 'Yükleniyor...',
              error: (_, __) => 'Email adresi kayıtlı değil',
            ),
            onTap: () => _showUpdateEmailDialog(context, ref),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.phone_outlined,
            title: 'Telefon Güncelle',
            subtitle: phoneAsync.when(
              data: (phone) => phone != null && phone.isNotEmpty
                  ? _formatPhoneDisplay(phone)
                  : 'Telefon numarası kayıtlı değil',
              loading: () => 'Yükleniyor...',
              error: (_, __) => 'Telefon numarası kayıtlı değil',
            ),
            onTap: () => _showUpdatePhoneDialog(context, ref),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.lock_outline,
            title: 'Şifre Değiştir',
            subtitle: 'Hesap güvenliğini sağla',
            onTap: () => _showChangePasswordDialog(context, ref),
          ),
          const SizedBox(height: 24),
          _LogoutButton(),
        ],
      ),
    );
  }

  String _formatPhoneDisplay(String phone) {
    if (phone.length == 10) {
      return '0 ${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({this.phone, this.email});

  final String? phone;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accentPurple, _darkPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accentPurple.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phone != null && phone!.isNotEmpty) ...[
                  Text(
                    _formatPhoneDisplay(phone!),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (email != null && email!.isNotEmpty) ...[
                  Text(
                    email!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if ((phone == null || phone!.isEmpty) &&
                    (email == null || email!.isEmpty))
                  const Text(
                    'Bilgilerinizi güncelleyin',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhoneDisplay(String phone) {
    if (phone.length == 10) {
      return '0 ${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _mediumPurple.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _mediumPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _accentPurple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _mediumPurple.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout, color: Colors.red.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

void _showUpdateEmailDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: MediaQuery.of(ctx).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _mediumPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.email_outlined, color: _accentPurple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Email Güncelle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Yeni email adresi',
                hintText: 'ornek@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentPurple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _accentPurple),
                  onPressed: () async {
                    await ref
                        .read(profileControllerProvider.notifier)
                        .updateEmail(controller.text.trim());
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ref.invalidate(cachedEmailProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email adresi güncellendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Güncelle'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
  );
}

void _showUpdatePhoneDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  final formatter = TrNationalPhoneInputFormatter();

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: MediaQuery.of(ctx).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _mediumPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_outlined, color: _accentPurple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Telefon Güncelle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [formatter],
              decoration: InputDecoration(
                labelText: 'Yeni telefon numarası',
                hintText: '0 5XX XXX XXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentPurple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _accentPurple),
                  onPressed: () async {
                    final digits =
                        TrNationalPhoneInputFormatter.toApiDigits(controller.text);
                    await ref
                        .read(profileControllerProvider.notifier)
                        .updatePhone(digits);
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ref.invalidate(cachedPhoneProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Telefon numarası güncellendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Güncelle'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
  );
}

void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  bool obscureCurrent = true;
  bool obscureNew = true;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: StatefulBuilder(
        builder: (ctx, setState) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _mediumPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline, color: _accentPurple),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Şifre Değiştir',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: currentController,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Mevcut şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accentPurple, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Yeni şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accentPurple, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _accentPurple),
                    onPressed: () async {
                      await ref
                          .read(profileControllerProvider.notifier)
                          .updatePassword(
                            currentPassword: currentController.text.trim(),
                            newPassword: newController.text.trim(),
                          );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Şifre başarıyla değiştirildi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Değiştir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    ),
  );
}

void _showLogoutDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 12),
          Text('Çıkış Yap'),
        ],
      ),
      content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ref.read(profileControllerProvider.notifier).logout();
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
              context.go('/login');
            }
          },
          child: const Text('Çıkış Yap'),
        ),
      ],
    ),
    ),
  );
}
