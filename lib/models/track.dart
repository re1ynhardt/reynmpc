/// Модель одного трека. Не зависит от конкретного бэкенда —
/// любой бэкенд (мок, REST, Firebase, локальные файлы и т.д.)
/// должен уметь отдавать данные именно в этом виде.
class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String artworkUrl;

  /// Прямая ссылка на аудиопоток. Для реального бэкенда это может быть
  /// подписанный URL, который нужно получать асинхронно — см.
  /// [AudioBackend.resolveStreamUrl] в backend/audio_backend.dart.
  final String audioUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.artworkUrl,
    required this.audioUrl,
  });

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
