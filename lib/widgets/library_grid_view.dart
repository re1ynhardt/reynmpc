import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/music_library.dart';
import '../localization/locale_controller.dart';
import '../models/playlist.dart';
import '../theme/app_theme.dart';

/// Сетка со всеми плейлистами пользователя — экран "Моя медиатека".
class LibraryGridView extends StatelessWidget {
  final List<Playlist> playlists;
  final ValueChanged<Playlist> onPlaylistTap;

  const LibraryGridView({
    super.key,
    required this.playlists,
    required this.onPlaylistTap,
  });

  // Константы карточки — держим их здесь же, чтобы точно посчитать
  // высоту плитки под контент и не полагаться на угаданный aspectRatio
  // (именно рассинхронизация угаданного соотношения с реальной высотой
  // контента и вызывала "BOTTOM OVERFLOWED").
  static const double _maxCrossAxisExtent = 200;
  static const double _spacing = 20;
  static const double _gridPadding = 24;
  static const double _cardPadding = 12;
  static const double _textAreaHeight = 10 /* отступ после обложки */ +
      20 /* название, 1 строка */ +
      4 /* отступ */ +
      34 /* описание, 2 строки */ +
      8 /* небольшой запас на разные метрики шрифта */;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      final s = context.watch<LocaleController>().s;
      final pal = AppColors.of(context);
      return Center(
        child: Text(s.libraryEmpty, style: TextStyle(color: pal.textSecondary)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(0.0, constraints.maxWidth - _gridPadding * 2);
        final crossAxisCount = math
            .max(1, (availableWidth / (_maxCrossAxisExtent + _spacing)).ceil());
        final usableWidth = math.max(0.0, availableWidth - _spacing * (crossAxisCount - 1));
        final tileWidth = usableWidth / crossAxisCount;

        // Обложка — квадрат по ширине содержимого карточки (ширина плитки
        // минус внутренние отступы), плюс фиксированная зона под текст —
        // так карточка ровно той высоты, которая нужна её содержимому.
        final imageHeight = math.max(0.0, tileWidth - _cardPadding * 2);
        final tileHeight = imageHeight + _textAreaHeight + _cardPadding * 2;
        final aspectRatio = tileHeight > 0 ? tileWidth / tileHeight : 1.0;

        return GridView.builder(
          padding: const EdgeInsets.all(_gridPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, i) {
            final playlist = playlists[i];
            return _LibraryCard(
              playlist: playlist,
              onTap: () => onPlaylistTap(playlist),
              onRename: (newName) => context.read<MusicLibrary>().renamePlaylist(playlist, newName),
              onDelete: () => context.read<MusicLibrary>().deletePlaylist(playlist),
            );
          },
        );
      },
    );
  }
}

class _LibraryCard extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;

  const _LibraryCard({
    required this.playlist,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<_LibraryCard> {
  bool _hovering = false;

  Future<void> _showRenameDialog(BuildContext context) async {
    final s = context.read<LocaleController>().s;
    final controller = TextEditingController(text: widget.playlist.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.renamePlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: s.playlistNameField),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.trim().isNotEmpty) {
      widget.onRename(newName);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final s = context.read<LocaleController>().s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deletePlaylist),
        content: Text(s.deletePlaylistConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final s = context.watch<LocaleController>().s;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovering ? pal.surfaceHigh : pal.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovering ? pal.glassBorder : Colors.transparent),
            boxShadow: _hovering
                ? [BoxShadow(color: pal.glassShadow, blurRadius: 24, offset: const Offset(0, 10))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: widget.playlist.isVirtual
                          ? const _LikedPlaylistCover()
                          : Image.network(
                              widget.playlist.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, error, stackTrace) => Container(color: pal.surfaceHigh),
                            ),
                    ),
                  ),
                  if (_hovering)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: pal.accent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: pal.accentGlow, blurRadius: 14)],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.play_arrow, color: pal.onAccent, size: 20),
                      ),
                    ),
                  if (_hovering && !widget.playlist.isVirtual)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Row(
                        children: [
                          _CoverGlassButton(icon: Icons.edit, onTap: () => _showRenameDialog(context)),
                          const SizedBox(width: 6),
                          _CoverGlassButton(icon: Icons.delete_outline, onTap: () => _showDeleteDialog(context)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.playlist.isVirtual ? s.likedLibraryName : widget.playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pal.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                widget.playlist.isVirtual ? s.likedLibraryDescription : widget.playlist.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pal.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Маленькая стеклянная круглая кнопка поверх обложки (редактировать/
/// удалить) — блюрит то, что под ней, вместо плоской чёрной заливки.
class _CoverGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CoverGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withOpacity(0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Обложка-заглушка для клиентских ("виртуальных") плейлистов вроде
/// Библиотека лайкнутых треков — градиент + сердце, как у Liked Songs в Spotify.
class _LikedPlaylistCover extends StatelessWidget {
  const _LikedPlaylistCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8395F0), Color(0xFFB33F86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.favorite, color: Colors.white, size: 40),
      ),
    );
  }
}
