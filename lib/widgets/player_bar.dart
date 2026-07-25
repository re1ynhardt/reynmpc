import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/music_library.dart';
import '../player/player_controller.dart';
import '../theme/app_theme.dart';
import 'track_artwork.dart';

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
    final library = context.watch<MusicLibrary>();
    final track = player.currentTrack;
    final pal = AppColors.of(context);
    final liked = track != null && library.isLiked(track);
    final hasArtwork = track != null && track.artworkUrl.isNotEmpty;
    const radius = 20.0;

    return Padding(
      // Отступы со всех сторон — панель "плавает" над фоном приложения,
      // а не прилипает к краям окна, как раньше.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: pal.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(color: pal.glassShadow, blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              // Размытая обложка текущего трека фоном под панелью — как и
              // раньше, только теперь скруглена вместе с самой панелью.
              if (hasArtwork)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                    child: Image.network(
                      track.artworkUrl,
                      fit: BoxFit.cover,
                      cacheHeight: 180,
                      errorBuilder: (ctx, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              if (hasArtwork)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          pal.surface.withOpacity(0.4),
                          pal.surface.withOpacity(0.94),
                        ],
                        stops: const [0.0, 0.65],
                      ),
                    ),
                  ),
                ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: pal.surface.withOpacity(hasArtwork ? 0.55 : 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Текущий трек: обложка + название/исполнитель + лайк.
                      SizedBox(
                        width: 250,
                        child: track == null
                            ? const SizedBox.shrink()
                            : Row(
                                children: [
                                  TrackArtwork(artworkUrl: track.artworkUrl, size: 52, elevated: true),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(track.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600, fontSize: 15, color: pal.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(track.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: pal.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => library.toggleLike(track),
                                    splashRadius: 16,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      liked ? Icons.favorite : Icons.favorite_border,
                                      size: 18,
                                      color: liked ? pal.accent : pal.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(width: 12),

                      // Транспортные кнопки.
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: pal.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: pal.accentGlow, blurRadius: 16, spreadRadius: 0),
                              ],
                            ),
                            child: IconButton(
                              icon: player.isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: pal.onAccent))
                                  : Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: pal.onAccent),
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

                      const SizedBox(width: 20),

                      // Прогресс-бар + тайминги.
                      Expanded(
                        child: Row(
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
                      ),

                      const SizedBox(width: 20),

                      // Громкость.
                      SizedBox(
                        width: 130,
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

                      IconButton(
                        icon: Icon(Icons.queue_music, size: 22, color: pal.textSecondary),
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
