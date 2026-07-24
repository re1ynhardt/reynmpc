import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      final s = context.watch<LocaleController>().s;
      return Center(
        child: Text(s.libraryEmpty, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.78,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, i) {
        final playlist = playlists[i];
        return _LibraryCard(playlist: playlist, onTap: () => onPlaylistTap(playlist));
      },
    );
  }
}

class _LibraryCard extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _LibraryCard({required this.playlist, required this.onTap});

  @override
  State<_LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<_LibraryCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.surfaceHigh : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        widget.playlist.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) => Container(color: AppColors.surfaceHigh),
                      ),
                    ),
                  ),
                  if (_hovering)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                widget.playlist.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
