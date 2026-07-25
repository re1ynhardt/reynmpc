import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../localization/app_strings.dart';
import '../localization/locale_controller.dart';
import '../theme/app_theme.dart';
import 'settings_dialog.dart';

/// Круглая аватарка аккаунта для сайдбара. По нажатию показывает
/// всплывающий виджет (AccountPopover) рядом с самой аватаркой —
/// с именем аккаунта, почтой и кнопкой выхода.
class AccountAvatarButton extends StatelessWidget {
  const AccountAvatarButton({super.key});

  String _initial(String? name, String? email) {
    final source = (name != null && name.trim().isNotEmpty) ? name.trim() : (email ?? '');
    return source.isNotEmpty ? source[0].toUpperCase() : '?';
  }

  void _openMenu(BuildContext buttonContext) {
    final renderBox = buttonContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(buttonContext).context.findRenderObject() as RenderBox;

    // Аватарка находится в правом верхнем углу окна, поэтому виджет
    // раскрывается вниз и остаётся прижатым к правому краю аватарки —
    // иначе он бы вылезал за пределы окна.
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset(renderBox.size.width, renderBox.size.height + 8), ancestor: overlay),
        renderBox.localToGlobal(Offset(renderBox.size.width, renderBox.size.height + 8), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: buttonContext,
      position: position,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      items: const [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _AccountPopoverContent(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final pal = AppColors.of(context);
    final initial = _initial(auth.currentUserName, auth.currentUserEmail);
    final avatarUrl = auth.currentUserAvatarUrl;

    return Builder(
      builder: (buttonContext) {
        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _openMenu(buttonContext),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: pal.accentGlow, blurRadius: 12)],
                image: avatarUrl != null
                    ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover, onError: (_, __) {})
                    : null,
              ),
              alignment: Alignment.center,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// Содержимое всплывающего виджета: имя аккаунта, почта и кнопка выхода.
class _AccountPopoverContent extends StatelessWidget {
  const _AccountPopoverContent();

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final auth = context.watch<AuthController>();
    final s = context.watch<LocaleController>().s;

    final name = auth.currentUserName ?? auth.currentUserEmail ?? '';
    final email = auth.currentUserEmail ?? '';
    final avatarUrl = auth.currentUserAvatarUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pal.glassFillStrong,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pal.glassBorder),
            boxShadow: [
              BoxShadow(color: pal.glassShadow, blurRadius: 28, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.red,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: pal.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: pal.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: pal.divider, height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(context: context, builder: (_) => const SettingsDialog());
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: pal.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(s.settings, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    auth.logout();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(s.authLogout, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
