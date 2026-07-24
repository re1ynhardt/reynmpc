import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/music_library.dart';
import '../localization/locale_controller.dart';
import '../models/nav_view.dart';
import '../theme/app_theme.dart';
import 'settings_dialog.dart';

class Sidebar extends StatelessWidget {
  final NavView activeView;
  final ValueChanged<NavView> onNavSelect;

  /// Вызывается, когда выбрали конкретный плейлист из списка внизу сайдбара —
  /// экран должен переключиться на "Главная" с открытым плейлистом.
  final ValueChanged<int> onPlaylistTap;

  const Sidebar({
    super.key,
    required this.activeView,
    required this.onNavSelect,
    required this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MusicLibrary>();
    final s = context.watch<LocaleController>().s;

    return Container(
      width: 240,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _LogoMark(size: 28),
                SizedBox(width: 8),
                Text(
                  'ReynM',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _NavItem(
            icon: Icons.home_filled,
            label: s.navHome,
            selected: activeView == NavView.home,
            onTap: () => onNavSelect(NavView.home),
          ),
          _NavItem(
            icon: Icons.search,
            label: s.navSearch,
            selected: activeView == NavView.search,
            onTap: () => onNavSelect(NavView.search),
          ),
          _NavItem(
            icon: Icons.library_music,
            label: s.navLibrary,
            selected: activeView == NavView.library,
            onTap: () => onNavSelect(NavView.library),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Divider(color: Colors.white12, height: 1),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(s.playlistsHeader, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: library.isLoadingPlaylists
                ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                : ListView.builder(
                    itemCount: library.playlists.length,
                    itemBuilder: (context, i) {
                      final playlist = library.playlists[i];
                      final selected = activeView == NavView.home && library.selectedPlaylist?.id == playlist.id;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: AppColors.surfaceHigh,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(playlist.coverUrl, width: 36, height: 36, fit: BoxFit.cover,
                              errorBuilder: (ctx, error, stackTrace) => Container(width: 36, height: 36, color: AppColors.surfaceHigh)),
                        ),
                        title: Text(
                          playlist.name,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onPlaylistTap(i),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white12, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                leading: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
                title: Text(s.settings, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                onTap: () => showDialog(context: context, builder: (_) => const SettingsDialog()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: AppColors.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          leading: Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 22),
          title: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: onTap,
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

  const _LogoMark({required this.size});

  // NB: constructor above is const on purpose — the surrounding widget tree
  // (Padding/Row in Sidebar.build) is a `const` literal, so every child
  // constructor in that subtree must be const-invokable.

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _RingPainter(),
        child: Center(
          child: Icon(Icons.music_note, color: Colors.white, size: size * 0.5),
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
