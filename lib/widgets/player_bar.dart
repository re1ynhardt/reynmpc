import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../player/player_controller.dart';
import '../theme/app_theme.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  String _fmt(Duration d) {
    if (d.isNegative) return '0:00';
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final track = player.currentTrack;
    final pal = AppColors.of(context);

    return Container(
      height: 90,
      color: pal.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Текущий трек
          SizedBox(
            width: 280,
            child: track == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(track.artworkUrl, width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) => Container(width: 56, height: 56, color: pal.surfaceHigh)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(track.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w500, color: pal.textPrimary)),
                            Text(track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: pal.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.favorite_border, size: 18, color: pal.textSecondary),
                    ],
                  ),
          ),

          // Центр: контролы + прогресс
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle, size: 18, color: player.shuffle ? pal.accent : pal.textSecondary),
                      onPressed: player.toggleShuffle,
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_previous, size: 22, color: pal.textPrimary),
                      onPressed: player.previous,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: pal.textPrimary, shape: BoxShape.circle),
                      child: IconButton(
                        icon: player.isLoading
                            ? SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: pal.background))
                            : Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: pal.background),
                        onPressed: player.hasTrack ? player.togglePlayPause : null,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, size: 22, color: pal.textPrimary),
                      onPressed: player.next,
                    ),
                    IconButton(
                      icon: Icon(
                        player.repeatMode == PlayerRepeatMode.one ? Icons.repeat_one : Icons.repeat,
                        size: 18,
                        color: player.repeatMode == PlayerRepeatMode.off ? pal.textSecondary : pal.accent,
                      ),
                      onPressed: player.cycleRepeatMode,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(_fmt(player.position), style: TextStyle(fontSize: 11, color: pal.textSecondary)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: pal.textPrimary,
                          inactiveTrackColor: pal.sliderInactive,
                          thumbColor: pal.textPrimary,
                        ),
                        child: Slider(
                          min: 0,
                          max: player.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                          value: player.position.inMilliseconds
                              .clamp(0, player.duration.inMilliseconds)
                              .toDouble(),
                          onChanged: player.hasTrack
                              ? (v) => player.seek(Duration(milliseconds: v.round()))
                              : null,
                        ),
                      ),
                    ),
                    Text(_fmt(player.duration), style: TextStyle(fontSize: 11, color: pal.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // Громкость
          SizedBox(
            width: 180,
            child: Row(
              children: [
                Icon(Icons.volume_up, size: 18, color: pal.textSecondary),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: pal.textPrimary,
                      inactiveTrackColor: pal.sliderInactive,
                      thumbColor: pal.textPrimary,
                    ),
                    child: Slider(
                      min: 0,
                      max: 1,
                      value: player.volume,
                      onChanged: player.setVolume,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
