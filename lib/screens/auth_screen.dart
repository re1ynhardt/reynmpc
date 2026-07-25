import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../localization/locale_controller.dart';
import '../theme/app_theme.dart';

/// Экран входа / регистрации, который показывается при запуске
/// приложения, пока пользователь не авторизован. После успешного входа
/// AuthController.isLoggedIn становится true, и AuthGate (см. main.dart)
/// сам переключается на HomeScreen — этот экран ничего никуда не
/// навигирует вручную.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterTab = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchTab(bool register) {
    if (_isRegisterTab == register) return;
    setState(() {
      _isRegisterTab = register;
      _errorText = null;
    });
  }

  String? _messageFor(AuthResult result) {
    final s = context.read<LocaleController>().s;
    switch (result) {
      case AuthResult.success:
        return null;
      case AuthResult.invalidInput:
        return s.authErrorInvalidInput;
      case AuthResult.invalidEmail:
        return s.authErrorInvalidEmail;
      case AuthResult.userNotFound:
        return s.authErrorUserNotFound;
      case AuthResult.wrongPassword:
        return s.authErrorWrongPassword;
      case AuthResult.userAlreadyExists:
        return s.authErrorUserExists;
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final auth = context.read<AuthController>();
    final email = _emailController.text;
    final password = _passwordController.text;

    final result = _isRegisterTab
        ? await auth.register(email, password, _nameController.text)
        : await auth.login(email, password);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorText = _messageFor(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final s = context.watch<LocaleController>().s;

    return Scaffold(
      backgroundColor: pal.background,
      body: Stack(
        children: [
          // Мягкое акцентное свечение в углу — оживляет плоский фон.
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [pal.accentGlow, pal.accentGlow.withOpacity(0)],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        color: pal.glassFill,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: pal.glassBorder),
                        boxShadow: [
                          BoxShadow(color: pal.glassShadow, blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                      ),
                      child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: pal.accentGlow, blurRadius: 24)],
                  ),
                  child: const Icon(Icons.music_note, color: AppColors.red, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  s.authWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                _TabSwitch(
                  isRegisterTab: _isRegisterTab,
                  loginLabel: s.authLoginTab,
                  registerLabel: s.authRegisterTab,
                  onChanged: _switchTab,
                ),
                const SizedBox(height: 24),
                if (_isRegisterTab) ...[
                  _AuthField(
                    controller: _nameController,
                    label: s.authNameField,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                ],
                _AuthField(
                  controller: _emailController,
                  label: s.authEmailField,
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  controller: _passwordController,
                  label: s.authPasswordField,
                  icon: Icons.lock_outline,
                  obscure: true,
                  onSubmitted: (_) => _submit(),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: pal.accentGlow, blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isRegisterTab ? s.authRegisterButton : s.authLoginButton,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ),
              ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSwitch extends StatelessWidget {
  final bool isRegisterTab;
  final String loginLabel;
  final String registerLabel;
  final ValueChanged<bool> onChanged;

  const _TabSwitch({
    required this.isRegisterTab,
    required this.loginLabel,
    required this.registerLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pal.glassFillStrong,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _TabButton(label: loginLabel, selected: !isRegisterTab, onTap: () => onChanged(false))),
          Expanded(child: _TabButton(label: registerLabel, selected: isRegisterTab, onTap: () => onChanged(true))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : pal.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: pal.glassFillStrong,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.glassBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: TextStyle(color: pal.textPrimary),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: pal.textSecondary),
          prefixIcon: Icon(icon, color: pal.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }
}
