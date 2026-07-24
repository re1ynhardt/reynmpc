import 'dart:math' as math;

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
      color: pal.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _LogoMark(size: 32, noteColor: pal.textPrimary),
          const SizedBox(height: 6),
          Text(
            'ReynM',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pal.textPrimary, letterSpacing: 0.5),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showDialog(context: context, builder: (_) => const SettingsDialog()),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings_outlined, color: pal.textSecondary, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        s.settings,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: pal.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
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

/// Логотип из icon.pdn: незамкнутое кольцо градиентом (сине-фиолетовое)
/// с разрывом снизу и белой музыкальной нотой внутри.
/// Фон и надпись "" из исходника сюда намеренно не перенесены.
class _LogoMark extends StatelessWidget {
  final double size;
  final Color noteColor;

  const _LogoMark({required this.size, this.noteColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _RingPainter(),
        child: Center(
          child: Icon(Icons.music_note, color: noteColor, size: size * 0.5),
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
