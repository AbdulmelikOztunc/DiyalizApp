import 'dart:convert';

import 'package:diyalizmobile/core/constants/api_endpoints.dart';
import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/core/network/dio_providers.dart';
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

final profileSyncProvider = FutureProvider<void>((ref) async {
  await ref.read(profileControllerProvider.notifier).syncProfileFromServer();
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> syncProfileFromServer() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiEndpoints.profile);
    if (response case ApiFailure<Map<String, dynamic>>()) {
      return;
    }

    final body = (response as ApiSuccess<Map<String, dynamic>>).data;
    if (body['success'] != true) {
      return;
    }

    final user = body['user'];
    if (user is! Map<String, dynamic>) {
      return;
    }

    final fullName = (user['full_name'] as String?)?.trim();
    final email = (user['email'] as String?)?.trim();
    final phone = (user['phone'] as String?)?.trim();
    final userId =
        '${user['id'] ?? ref.read(authControllerProvider).user?.id ?? ''}';

    final prefs = await ref.read(sharedPreferencesProvider.future);

    if (email != null && email.isNotEmpty) {
      await prefs.setString('notification_email', email);
    } else {
      await prefs.remove('notification_email');
    }

    if (phone != null && phone.isNotEmpty) {
      await prefs.setString('cached_phone', phone);
    }

    if (fullName != null && fullName.isNotEmpty) {
      await prefs.setString(
        'cached_user',
        jsonEncode({'id': userId, 'fullName': fullName}),
      );
      ref
          .read(authControllerProvider.notifier)
          .updateUserProfile(fullName: fullName);
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
  }) async {
    final trimmedFullName = fullName.trim();
    final trimmedEmail = email.trim();

    if (trimmedFullName.isEmpty) {
      state = state.copyWith(errorMessage: 'Ad soyad boş olamaz');
      return false;
    }
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'Email adresi boş olamaz');
      return false;
    }
    if (!_looksLikeEmail(trimmedEmail)) {
      state = state.copyWith(errorMessage: 'Geçerli bir email adresi girin');
      return false;
    }

    state = state.copyWith(isLoading: true);

    final api = ref.read(apiClientProvider);
    final response = await api.post(
      ApiEndpoints.profile,
      data: {'full_name': trimmedFullName, 'email': trimmedEmail},
    );

    if (response case ApiFailure<Map<String, dynamic>>(:final error)) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    }

    final body = (response as ApiSuccess<Map<String, dynamic>>).data;
    final success = body['success'] == true;
    final message = (body['message'] as String?)?.trim();
    if (!success) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: (message != null && message.isNotEmpty)
            ? message
            : 'Profil güncellenemedi',
      );
      return false;
    }

    await syncProfileFromServer();

    state = state.copyWith(
      isLoading: false,
      successMessage: (message != null && message.isNotEmpty)
          ? message
          : 'Profil bilgileri güncellendi',
    );
    return true;
  }

  Future<bool> updatePhone(String newPhone) async {
    final trimmedPhone = newPhone.trim();
    if (trimmedPhone.isEmpty) {
      state = state.copyWith(errorMessage: 'Telefon numarası boş olamaz');
      return false;
    }
    if (trimmedPhone.length != 11 || !trimmedPhone.startsWith('0')) {
      state = state.copyWith(
        errorMessage: 'Geçerli bir telefon numarası girin',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final api = ref.read(apiClientProvider);
    final response = await api.post(
      ApiEndpoints.updatePhone,
      data: {'new_phone': trimmedPhone},
    );

    if (response case ApiFailure<Map<String, dynamic>>(:final error)) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    }

    final body = (response as ApiSuccess<Map<String, dynamic>>).data;
    final success = body['success'] == true;
    final message = (body['message'] as String?)?.trim();
    if (!success) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: (message != null && message.isNotEmpty)
            ? message
            : 'Telefon numarası güncellenemedi',
      );
      return false;
    }

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('cached_phone', trimmedPhone);
    await syncProfileFromServer();

    state = state.copyWith(
      isLoading: false,
      successMessage: (message != null && message.isNotEmpty)
          ? message
          : 'Telefon numarası güncellendi',
    );
    return true;
  }

  Future<void> updateEmail(String newEmail) async {
    final trimmedEmail = newEmail.trim();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'Email adresi boş olamaz');
      return;
    }
    if (!_looksLikeEmail(trimmedEmail)) {
      state = state.copyWith(errorMessage: 'Geçerli bir email adresi girin');
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

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Tüm alanları doldurun');
      return false;
    }
    if (newPassword.length < 6) {
      state = state.copyWith(
        errorMessage: 'Yeni şifre en az 6 karakter olmalı',
      );
      return false;
    }

    state = state.copyWith(isLoading: true);

    final api = ref.read(apiClientProvider);
    final response = await api.post(
      ApiEndpoints.profile,
      data: {
        'current_password': currentPassword.trim(),
        'password': newPassword.trim(),
      },
    );

    if (response case ApiFailure<Map<String, dynamic>>(:final error)) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    }

    final body = (response as ApiSuccess<Map<String, dynamic>>).data;
    final success = body['success'] == true;
    final message = (body['message'] as String?)?.trim();

    if (!success) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: (message != null && message.isNotEmpty)
            ? message
            : 'Şifre güncellenemedi',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      successMessage: (message != null && message.isNotEmpty)
          ? message
          : 'Şifre başarıyla değiştirildi',
    );
    return true;
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
