import 'package:diyalizmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:diyalizmobile/features/auth/presentation/utils/tr_national_phone_input_formatter.dart';
import 'package:diyalizmobile/features/auth/presentation/widgets/glass_auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;
  bool _phoneError = false;
  bool _passwordError = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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
              final titleToCardGap = (h * 0.065).clamp(48.0, 100.0);

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
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  height: 1.5,
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
                                      isError: _phoneError,
                                      onChanged: (_) {
                                        if (_phoneError) {
                                          setState(() => _phoneError = false);
                                        }
                                      },
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: false,
                                            signed: false,
                                          ),
                                      inputFormatters: [
                                        TrNationalPhoneInputFormatter(),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    AuthPillTextField(
                                      controller: _passwordController,
                                      hintText: 'Şifre',
                                      obscureText: true,
                                      isError: _passwordError,
                                      onChanged: (_) {
                                        if (_passwordError) {
                                          setState(
                                            () => _passwordError = false,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    AuthPrimaryButton(
                                      label: 'Giriş Yap',
                                      isLoading: authState.isLoading,
                                      onPressed: authState.isLoading
                                          ? null
                                          : _submit,
                                    ),
                                    const SizedBox(height: 40),
                                    AuthSecondaryButton(
                                      label: 'Hesabım yok Kayıt Oluştur',
                                      onPressed: () =>
                                          context.push('/register'),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      horizontal,
                      6,
                      horizontal,
                      12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: TextButton(
                          onPressed: () => context.push('/about'),
                          child: const Text(
                            'Uygulama Hakkında Bilgi Al',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              decorationColor: Colors.white,
                            ),
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

    final displayDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (displayDigits.length != 11) {
      setState(() {
        _localError = 'Telefon numarası 11 hane olmalı';
        _phoneError = true;
        _passwordError = false;
      });
      return;
    }

    final password = _passwordController.text;
    if (password.length < 4) {
      setState(() {
        _localError = 'Şifre en az 4 karakter olmalı';
        _passwordError = true;
        _phoneError = false;
      });
      return;
    }

    setState(() {
      _phoneError = false;
      _passwordError = false;
    });

    ref
        .read(authControllerProvider.notifier)
        .login(
          phoneNumber: TrNationalPhoneInputFormatter.toApiDigits(
            _phoneController.text,
          ),
          password: password,
        );
  }
}
