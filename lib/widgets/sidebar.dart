import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/locale_controller.dart';
import '../models/nav_view.dart';
import '../theme/app_theme.dart';
import 'settings_dialog.dart';

/// Полный сайдбар в стиле референса: логотип сверху, список разделов
/// навигации и небольшая карточка-плашка снизу. Разделы, для которых
/// в приложении пока нет отдельного экрана (Обзор/Плейлисты/Сообщество/
/// Загрузки), ведут на Главную — они здесь только визуально, как в макете.
class Sidebar extends StatelessWidget {
  final NavView activeView;
  final ValueChanged<NavView> onNavSelect;
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
      width: 230,
      decoration: BoxDecoration(
        color: pal.sidebar,
        border: Border(right: BorderSide(color: pal.glassBorder, width: 1)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: pal.glassFill.withOpacity(pal.glassFill.opacity * 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),
                Row(
                  children: [
                    const _LogoMark(size: 26, noteColor: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'ReynM',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold, color: pal.textPrimary, letterSpacing: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _NavEntry(
                  icon: Icons.home_filled,
                  label: s.navHome,
                  selected: activeView == NavView.home,
                  onTap: () => onNavSelect(NavView.home),
                ),
                const _NavEntry(icon: Icons.query_stats_rounded, label: 'Обзор', selected: false),
                _NavEntry(
                  icon: Icons.grid_view_rounded,
                  label: 'Библиотека',
                  selected: activeView == NavView.library,
                  onTap: () => onNavSelect(NavView.library),
                ),
                const _NavEntry(icon: Icons.queue_music_rounded, label: 'Плейлисты', selected: false),
                const _NavEntry(icon: Icons.groups_rounded, label: 'Сообщество', selected: false),
                const _NavEntry(icon: Icons.download_rounded, label: 'Загрузки', selected: false),
                const Spacer(),
                _NavEntry(
                  icon: Icons.settings_outlined,
                  label: s.settings,
                  selected: false,
                  onTap: () => showDialog(context: context, builder: (_) => const SettingsDialog()),
                ),
                const SizedBox(height: 12),
                _AmbientCard(pal: pal),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Один пункт вертикальной навигации — иконка + подпись, с подсветкой
/// активного/наведённого состояния.
class _NavEntry extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavEntry({required this.icon, required this.label, required this.selected, this.onTap});

  @override
  State<_NavEntry> createState() => _NavEntryState();
}

class _NavEntryState extends State<_NavEntry> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final active = widget.selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF3D6BF0).withOpacity(0.18)
                    : (_hovering ? pal.glassFill : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: active ? Border.all(color: const Color(0xFF3D6BF0).withOpacity(0.4)) : null,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 19, color: active ? const Color(0xFF6E93FF) : pal.textSecondary),
                  const SizedBox(width: 14),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? pal.textPrimary : pal.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Небольшая декоративная карточка внизу сайдбара ("Rain outside")
/// — статична, просто задаёт настроение, как в макете.
class _AmbientCard extends StatelessWidget {
  final AppPalette pal;
  const _AmbientCard({required this.pal});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2740), Color(0xFF0E1420)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Rain outside',
                      style: TextStyle(color: pal.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Perfect time for music',
                      style: TextStyle(color: pal.textSecondary, fontSize: 10.5)),
                ],
              ),
            ),
            Icon(Icons.graphic_eq_rounded, color: pal.textSecondary.withOpacity(0.8), size: 20),
          ],
        ),
      ),
    );
  }
}

/// Логотип из icon.pdn: незамкнутое кольцо градиентом (сине-фиолетовое)
/// с разрывом снизу и белой музыкальной нотой внутри.
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
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(size.width * 0.08);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF8395F0), Color(0xFFA3B4E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    const startAngle = 0.36 * math.pi;
    const sweepAngle = 2 * math.pi - 0.72 * math.pi;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}
