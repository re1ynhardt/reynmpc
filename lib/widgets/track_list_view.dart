import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/music_library.dart';
import '../localization/locale_controller.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../player/player_controller.dart';
import '../theme/app_theme.dart';
import 'track_artwork.dart';

class TrackListView extends StatelessWidget {
  final List<Track> tracks;

  const TrackListView({super.key, required this.tracks});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final s = context.watch<LocaleController>().s;
    final pal = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 32, child: Text('#', style: TextStyle(color: pal.textSecondary))),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: Text(s.columnTitle, style: TextStyle(color: pal.textSecondary, fontSize: 12))),
              Expanded(flex: 3, child: Text(s.columnAlbum, style: TextStyle(color: pal.textSecondary, fontSize: 12))),
              Icon(Icons.access_time, size: 16, color: pal.textSecondary),
              const SizedBox(width: 24),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Divider(color: pal.divider, height: 1),
        ),
        ...List.generate(tracks.length, (i) {
          final track = tracks[i];
          final isCurrent = player.currentTrack?.id == track.id;
          final library = context.watch<MusicLibrary>();
          final ownPlaylists = library.playlists.where((p) => !p.isVirtual).toList();
          return _TrackRow(
            index: i + 1,
            track: track,
            isCurrent: isCurrent,
            isPlaying: isCurrent && player.isPlaying,
            isLiked: library.isLiked(track),
            durationLabel: _formatDuration(track.duration),
            onTap: () => player.playFromList(tracks, i),
            onToggleLike: () => library.toggleLike(track),
            playlists: ownPlaylists,
            loadMembership: () => library.playlistIdsContainingTrack(track, ownPlaylists),
            onAddToPlaylist: (playlist) => library.addTrackToPlaylist(track, playlist),
            onRemoveFromPlaylist: (playlist) => library.removeTrackFromPlaylist(track, playlist),
          );
        }),
      ],
    );
  }
}

class _TrackRow extends StatefulWidget {
  final int index;
  final Track track;
  final bool isCurrent;
  final bool isPlaying;
  final bool isLiked;
  final String durationLabel;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;
  final List<Playlist> playlists;
  final Future<Set<String>> Function() loadMembership;
  final ValueChanged<Playlist> onAddToPlaylist;
  final ValueChanged<Playlist> onRemoveFromPlaylist;

  const _TrackRow({
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.isLiked,
    required this.durationLabel,
    required this.onTap,
    required this.onToggleLike,
    required this.playlists,
    required this.loadMembership,
    required this.onAddToPlaylist,
    required this.onRemoveFromPlaylist,
  });

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  bool _hovering = false;

  Future<void> _openAddToPlaylistMenu(BuildContext context, Offset globalPosition) async {
    final s = context.read<LocaleController>().s;
    final pal = AppColors.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    if (widget.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.addToPlaylistEmpty)));
      return;
    }

    // Узнаём, в каких плейлистах трек уже есть, ДО открытия меню — чтобы
    // сразу нарисовать галочки, а не мигать пустым меню и дозагружать их.
    final memberIds = await widget.loadMembership();
    if (!context.mounted) return;

    final selected = await showMenu<Playlist>(
      context: context,
      position: RelativeRect.fromRect(globalPosition & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        PopupMenuItem<Playlist>(enabled: false, child: Text(s.addToPlaylist, style: const TextStyle(fontWeight: FontWeight.bold))),
        const PopupMenuDivider(),
        for (final playlist in widget.playlists)
          PopupMenuItem<Playlist>(
            value: playlist,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: memberIds.contains(playlist.id) ? Icon(Icons.check, size: 18, color: pal.accent) : null,
                ),
                const SizedBox(width: 4),
                Expanded(child: Text(playlist.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
    );

    if (selected == null) return;

    // Повторное нажатие на плейлист, где трек уже есть, — убирает его
    // оттуда (тот же пункт меню работает как переключатель).
    if (memberIds.contains(selected.id)) {
      widget.onRemoveFromPlaylist(selected);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${s.removedFromPlaylist}: ${selected.name}')));
      }
    } else {
      widget.onAddToPlaylist(selected);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${s.addedToPlaylist}: ${selected.name}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final titleColor = widget.isCurrent ? pal.accent : pal.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hovering ? pal.hoverOverlay : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: _hovering
                    ? Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow, size: 18, color: pal.textPrimary)
                    : Text('${widget.index}', style: TextStyle(color: pal.textSecondary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    TrackArtwork(artworkUrl: widget.track.artworkUrl, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: titleColor, fontWeight: FontWeight.w500)),
                          Text(widget.track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: pal.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(widget.track.album,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: pal.textSecondary)),
              ),
              SizedBox(
                width: 32,
                child: (_hovering || widget.isLiked)
                    ? IconButton(
                        onPressed: widget.onToggleLike,
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          widget.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: widget.isLiked ? pal.accent : pal.textSecondary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.durationLabel, style: TextStyle(color: pal.textSecondary)),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: _hovering
                    ? Builder(
                        builder: (buttonContext) => IconButton(
                          onPressed: () {
                            final renderBox = buttonContext.findRenderObject() as RenderBox;
                            final position = renderBox.localToGlobal(renderBox.size.bottomLeft(Offset.zero));
                            _openAddToPlaylistMenu(buttonContext, position);
                          },
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.more_horiz, size: 18, color: pal.textSecondary),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
