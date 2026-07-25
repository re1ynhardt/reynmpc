import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../localization/app_language.dart';
import '../localization/locale_controller.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final themeController = context.watch<ThemeController>();
    final auth = context.watch<AuthController>();
    final pal = AppColors.of(context);
    final s = locale.s;

    return Dialog(
      backgroundColor: pal.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.settingsTitle,
                    style: TextStyle(color: pal.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: pal.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (auth.currentUserEmail != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.account_circle_outlined, size: 18, color: pal.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.authLoggedInAs} ${auth.currentUserName ?? auth.currentUserEmail}',
                        style: TextStyle(color: pal.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                s.themeLabel,
                style: TextStyle(color: pal.textSecondary, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                label: s.themeDark,
                icon: Icons.dark_mode_outlined,
                selected: themeController.mode == ThemeMode.dark,
                onTap: () => themeController.setMode(ThemeMode.dark),
              ),
              _ThemeOption(
                label: s.themeLight,
                icon: Icons.light_mode_outlined,
                selected: themeController.mode == ThemeMode.light,
                onTap: () => themeController.setMode(ThemeMode.light),
              ),
              const SizedBox(height: 16),
              Text(
                s.languageLabel,
                style: TextStyle(color: pal.textSecondary, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                label: s.languageRu,
                selected: locale.language == AppLanguage.ru,
                onTap: () => locale.setLanguage(AppLanguage.ru),
              ),
              _LanguageOption(
                label: s.languageEn,
                selected: locale.language == AppLanguage.en,
                onTap: () => locale.setLanguage(AppLanguage.en),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.close, style: const TextStyle(color: AppColors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppColors.red : pal.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Icon(icon, size: 18, color: selected ? pal.textPrimary : pal.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? pal.textPrimary : pal.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppColors.red : pal.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? pal.textPrimary : pal.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
