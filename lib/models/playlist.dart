/// Модель плейлиста. Список id треков хранится отдельно от самих треков,
/// т.к. реальный бэкенд обычно отдаёт треки плейлиста отдельным запросом
/// (пагинация, ленивая подгрузка и т.д.) — см. [AudioBackend.fetchTracksForPlaylist].
class Playlist {
  final String id;
  final String name;
  final String coverUrl;
  final String description;

  /// true для сущностей, которые собирает само приложение на клиенте, а не
  /// бэкенд (например библиотека лайкнутых треков — концептуально это не
  /// плейлист, а отдельная библиотека, но она использует ту же модель для
  /// простоты отображения в общем списке/сетке). Такие записи не имеют
  /// обложки от бэкенда — UI рисует для них собственную заглушку.
  final bool isVirtual;

  const Playlist({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.description = '',
    this.isVirtual = false,
  });

  @override
  bool operator ==(Object other) => other is Playlist && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
