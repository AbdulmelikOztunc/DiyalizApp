import 'package:diyalizmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  ProfileState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

final cachedPhoneProvider = FutureProvider<String?>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getString('cached_phone');
});

final cachedEmailProvider = FutureProvider<String?>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getString('notification_email');
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> updatePhone(String newPhone) async {
    if (newPhone.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Telefon numarası boş olamaz',
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    // TODO: API entegrasyonu yapıldığında bu blok gerçek çağrıyla
    // değiştirilecek: PATCH /v1/me/phone
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('cached_phone', newPhone);

    state = state.copyWith(
      isLoading: false,
      successMessage: 'Telefon numarası güncellendi',
    );
  }

  Future<void> updateEmail(String newEmail) async {
    final trimmedEmail = newEmail.trim();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Email adresi boş olamaz',
      );
      return;
    }
    if (!_looksLikeEmail(trimmedEmail)) {
      state = state.copyWith(
        errorMessage: 'Geçerli bir email adresi girin',
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    // TODO: API entegrasyonu yapıldığında bu blok gerçek çağrıyla
    // değiştirilecek: PATCH /v1/me/email
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('notification_email', trimmedEmail);

    state = state.copyWith(
      isLoading: false,
      successMessage: 'Email adresi güncellendi',
    );
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Tüm alanları doldurun',
      );
      return;
    }
    if (newPassword.length < 6) {
      state = state.copyWith(
        errorMessage: 'Yeni şifre en az 6 karakter olmalı',
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    // TODO: API entegrasyonu yapıldığında bu blok gerçek çağrıyla
    // değiştirilecek: PATCH /v1/me/password
    await Future<void>.delayed(const Duration(milliseconds: 600));

    state = state.copyWith(
      isLoading: false,
      successMessage: 'Şifre başarıyla değiştirildi',
    );
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@([^@\s]+\.)+[^@\s]+$').hasMatch(value);
  }

  void clearMessages() {
    state = state.copyWith();
  }

  Future<void> logout() async {
    await ref.read(authControllerProvider.notifier).logout();
  }
}
