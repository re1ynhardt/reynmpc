import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/locale_controller.dart';
import '../models/nav_view.dart';
import '../theme/app_theme.dart';
import 'settings_dialog.dart';

/// Урезанный сайдбар: только логотип сверху и настройки снизу.
/// Навигация (Главная / Поиск / Моя медиатека) и список плейлистов
/// переехали в виджеты по центру верхней панели — см. HomeScreen._TopBar.
class Sidebar extends StatelessWidget {
  final NavView activeView;
  final ValueChanged<NavView> onNavSelect;

  /// Оставлен для совместимости с вызывающим кодом — плейлисты
  /// в сайдбаре больше не отображаются.
  final ValueChanged<int> onPlaylistTap;

  const Sidebar({
    super.key,
    required this.activeView,
    required this.onNavSelect,
    required this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final pal = AppColors.of(context);

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: pal.sidebar,
        border: Border(right: BorderSide(color: pal.glassBorder, width: 1)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: pal.glassFill.withOpacity(pal.glassFill.opacity * 0.5),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _LogoMark(size: 32, noteColor: pal.textPrimary),
                const SizedBox(height: 6),
                Text(
                  'ReynM',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: pal.textPrimary, letterSpacing: 0.5),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _SettingsEntry(label: s.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка настроек с плавной "стеклянной" подсветкой при наведении —
/// в той же визуальной системе, что и пилюли навигации в верхней панели.
class _SettingsEntry extends StatefulWidget {
  final String label;
  const _SettingsEntry({required this.label});

  @override
  State<_SettingsEntry> createState() => _SettingsEntryState();
}

class _SettingsEntryState extends State<_SettingsEntry> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showDialog(context: context, builder: (_) => const SettingsDialog()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hovering ? pal.glassFill : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _hovering ? pal.glassBorder : Colors.transparent),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined,
                    color: _hovering ? pal.textPrimary : pal.textSecondary, size: 22),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _hovering ? pal.textPrimary : pal.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

/// Логотип из icon.pdn: незамкнутое кольцо градиентом (сине-фиолетовое)
/// с разрывом снизу и белой музыкальной нотой внутри.
/// Фон и надпись "" из исходника сюда намеренно не перенесены.
class _LogoMark extends StatelessWidget {
  final double size;
  final Color noteColor;

  const _LogoMark({required this.size, this.noteColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8395F0).withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: const _RingPainter(),
          child: Center(
            child: Icon(Icons.music_note, color: noteColor, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(size.width * 0.08);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF8395F0), Color(0xFFA3B4E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    // Кольцо с разрывом снизу — как в оригинальном логотипе.
    const startAngle = 0.36 * math.pi;
    const sweepAngle = 2 * math.pi - 0.72 * math.pi;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}
