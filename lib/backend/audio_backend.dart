import '../models/playlist.dart';
import '../models/track.dart';

/// Единый контракт для источника данных плеера.
///
/// Всё приложение (UI, плеер, библиотека) работает только с этим
/// интерфейсом и ничего не знает о том, откуда реально берутся данные.
/// Чтобы подключить свой бэкенд — реализуйте этот класс и замените
/// ОДНУ строку в main.dart:
///
///   runApp(SpotifyCloneApp(backend: MockAudioBackend()));
///                                    ^^^^^^^^^^^^^^^^ поменять на свой,
///                                    например RestAudioBackend(baseUrl: ...)
abstract class AudioBackend {
  /// Список плейлистов для главного экрана / сайдбара.
  Future<List<Playlist>> fetchPlaylists();

  /// Треки конкретного плейлиста.
  Future<List<Track>> fetchTracksForPlaylist(String playlistId);

  /// Поиск треков по строке запроса.
  Future<List<Track>> searchTracks(String query);

  /// Получить реально проигрываемый URL для трека.
  ///
  /// Вынесено отдельным методом (а не просто `track.audioUrl`), потому что
  /// у реальных бэкендов это часто асинхронная операция: нужно получить
  /// подписанный/временный URL, обновить токен и т.п. Мок-реализация может
  /// просто вернуть `track.audioUrl` синхронно, обёрнутый в Future.
  Future<String> resolveStreamUrl(Track track);
}
