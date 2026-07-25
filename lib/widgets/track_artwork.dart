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

  /// Мягкая приподнятая тень под обложкой — включается только для более
  /// крупных обложек (плеер, шапка плейлиста), чтобы не перегружать
  /// плотные списки треков лишними тенями.
  final bool elevated;

  const TrackArtwork({
    super.key,
    required this.artworkUrl,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.elevated = false,
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

    final image = ClipRRect(
      borderRadius: borderRadius,
      child: artworkUrl.isEmpty
          ? placeholder()
          : Image.network(
              artworkUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // gaplessPlayback — переиспользовать уже закэшированный кадр
              // вместо мигания пустотой, пока (если) идёт повторная загрузка.
              gaplessPlayback: true,
              // Декодируем сразу под нужный размер виджета (с запасом под
              // Retina-экраны), а не в исходном разрешении с сервера —
              // иначе даже ограниченный по количеству ImageCache может
              // раздуться по памяти на паре десятков крупных обложек.
              cacheWidth: (size * 2).round(),
              cacheHeight: (size * 2).round(),
              errorBuilder: (ctx, error, stackTrace) => placeholder(),
            ),
    );

    if (!elevated) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: pal.glassShadow, blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: image,
    );
  }
}
