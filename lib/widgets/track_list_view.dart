import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/locale_controller.dart';
import '../models/track.dart';
import '../player/player_controller.dart';
import '../theme/app_theme.dart';

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
          return _TrackRow(
            index: i + 1,
            track: track,
            isCurrent: isCurrent,
            isPlaying: isCurrent && player.isPlaying,
            durationLabel: _formatDuration(track.duration),
            onTap: () => player.playFromList(tracks, i),
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
  final String durationLabel;
  final VoidCallback onTap;

  const _TrackRow({
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.durationLabel,
    required this.onTap,
  });

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  bool _hovering = false;

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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(widget.track.artworkUrl, width: 40, height: 40, fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stackTrace) => Container(width: 40, height: 40, color: pal.surfaceHigh)),
                    ),
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
              Text(widget.durationLabel, style: TextStyle(color: pal.textSecondary)),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}
