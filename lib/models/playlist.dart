/// Модель плейлиста. Список id треков хранится отдельно от самих треков,
/// т.к. реальный бэкенд обычно отдаёт треки плейлиста отдельным запросом
/// (пагинация, ленивая подгрузка и т.д.) — см. [AudioBackend.fetchTracksForPlaylist].
class Playlist {
  final String id;
  final String name;
  final String coverUrl;
  final String description;

  const Playlist({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.description = '',
  });

  @override
  bool operator ==(Object other) => other is Playlist && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
