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
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            // Непрозрачный градиент вместо сплошного цвета: тёмная база темы
            // (surfaceHigh) не зависит от барьера showDialog() позади себя,
            // а лёгкий блик сверху даёт стеклянный вид без реального блюра.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(pal.glassHighlight, pal.surfaceHigh),
                pal.surfaceHigh,
              ],
              stops: const [0.0, 0.5],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pal.glassBorder),
            boxShadow: [
              BoxShadow(color: pal.glassShadow, blurRadius: 32, offset: const Offset(0, 16)),
            ],
          ),
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
              _SegmentedGroup(
                children: [
                  _SegmentOption(
                    label: s.themeDark,
                    icon: Icons.dark_mode_outlined,
                    selected: themeController.mode == ThemeMode.dark,
                    onTap: () => themeController.setMode(ThemeMode.dark),
                  ),
                  _SegmentOption(
                    label: s.themeLight,
                    icon: Icons.light_mode_outlined,
                    selected: themeController.mode == ThemeMode.light,
                    onTap: () => themeController.setMode(ThemeMode.light),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                s.languageLabel,
                style: TextStyle(color: pal.textSecondary, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              _SegmentedGroup(
                children: [
                  _SegmentOption(
                    label: s.languageRu,
                    selected: locale.language == AppLanguage.ru,
                    onTap: () => locale.setLanguage(AppLanguage.ru),
                  ),
                  _SegmentOption(
                    label: s.languageEn,
                    selected: locale.language == AppLanguage.en,
                    onTap: () => locale.setLanguage(AppLanguage.en),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
          ),
    );
  }
}

/// Единый контейнер-пилюля для сегментированного выбора (тема/язык) —
/// в той же стеклянной эстетике, что и группа навигации в верхней панели.
class _SegmentedGroup extends StatelessWidget {
  final List<Widget> children;
  const _SegmentedGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pal.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pal.glassBorder),
      ),
      child: Row(children: children.map((c) => Expanded(child: c)).toList()),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentOption({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? pal.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? pal.onAccent : pal.textSecondary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? pal.onAccent : pal.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
