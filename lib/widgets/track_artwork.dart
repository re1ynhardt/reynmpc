import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Квадратная обложка трека. Если у трека нет [artworkUrl] или картинка
/// не загрузилась — вместо пустого серого квадрата рисуем такой же
/// квадрат с иконкой ноты по центру, чтобы список треков не выглядел
/// как набор пустых плейсхолдеров.
class TrackArtwork extends StatelessWidget {
  final String artworkUrl;
  final double size;
  final BorderRadius borderRadius;

  const TrackArtwork({
    super.key,
    required this.artworkUrl,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);

    Widget placeholder() => Container(
          width: size,
          height: size,
          color: pal.surfaceHigh,
          alignment: Alignment.center,
          child: Icon(Icons.music_note, size: size * 0.5, color: pal.textSecondary),
        );

    return ClipRRect(
      borderRadius: borderRadius,
      child: artworkUrl.isEmpty
          ? placeholder()
          : Image.network(
              artworkUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (ctx, error, stackTrace) => placeholder(),
            ),
    );
  }
}
