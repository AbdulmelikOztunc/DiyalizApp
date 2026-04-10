import 'package:diyalizmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:diyalizmobile/features/auth/presentation/utils/tr_national_phone_input_formatter.dart';
import 'package:diyalizmobile/features/auth/presentation/widgets/glass_auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordAgainController = TextEditingController();
  final _emailController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.isAuthenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4E5AE2), Color.fromARGB(255, 25, 0, 90)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              const horizontal = 24.0;
              final topPad = (h * 0.04).clamp(20.0, 56.0);
              final titleToCardGap = (h * 0.05).clamp(36.0, 80.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        topPad,
                        horizontal,
                        16,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Hemodiyaliz Eğitim Platformu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  height: 1.4,
                                ),
                              ),

                              SizedBox(height: titleToCardGap),
                              GlassAuthCard(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AuthPillTextField(
                                      controller: _phoneController,
                                      hintText: 'Telefon Numarası',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: false,
                                            signed: false,
                                          ),
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        TrNationalPhoneInputFormatter(),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    AuthPillTextField(
                                      controller: _passwordController,
                                      hintText: 'Şifre',
                                      obscureText: true,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 14),
                                    AuthPillTextField(
                                      controller: _passwordAgainController,
                                      hintText: 'Şifre (tekrar)',
                                      obscureText: true,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 14),
                                    AuthPillTextField(
                                      controller: _emailController,
                                      hintText: 'E-posta (isteğe bağlı)',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Uzmanınız sorunuza yanıt verdiğinde '
                                      'haberdar olmak için e-posta ekleyebilirsiniz. ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    AuthPrimaryButton(
                                      label: 'Kayıt Ol',
                                      isLoading: authState.isLoading,
                                      onPressed: authState.isLoading
                                          ? null
                                          : _submit,
                                    ),
                                    const SizedBox(height: 16),
                                    AuthSecondaryButton(
                                      label: 'Zaten hesabım var — Giriş Yap',
                                      onPressed: () => context.pop(),
                                    ),
                                    if (_localError != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _localError!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFFFFDADA),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    if (authState.errorMessage != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        authState.errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFFFFDADA),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _localError = null);

    final password = _passwordController.text;
    final again = _passwordAgainController.text;
    if (password != again) {
      setState(() {
        _localError = 'Şifreler eşleşmiyor';
      });
      return;
    }

    ref
        .read(authControllerProvider.notifier)
        .register(
          phoneNumber: TrNationalPhoneInputFormatter.toApiDigits(
            _phoneController.text,
          ),
          password: password,
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );
  }
}
