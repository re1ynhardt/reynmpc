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
  /// Список плейлистов для главного экрана / сайдбара, принадлежащих
  /// пользователю [userId] (null — гость / нет сессии: пустой список,
  /// без чужих плейлистов).
  Future<List<Playlist>> fetchPlaylists(String? userId);

  /// Треки конкретного плейлиста.
  Future<List<Track>> fetchTracksForPlaylist(String playlistId);

  /// Все треки, загруженные в плеер (используется на Главной, где
  /// показываются первые 100 из них — см. [MusicLibrary.homeTracks]).
  Future<List<Track>> fetchAllTracks();

  /// Поиск треков по строке запроса.
  Future<List<Track>> searchTracks(String query);

  /// Переименовать плейлист. Возвращает обновлённый [Playlist].
  Future<Playlist> renamePlaylist(String playlistId, String newName);

  /// Удалить плейлист.
  Future<void> deletePlaylist(String playlistId);

  /// Получить реально проигрываемый URL для трека.
  ///
  /// Вынесено отдельным методом (а не просто `track.audioUrl`), потому что
  /// у реальных бэкендов это часто асинхронная операция: нужно получить
  /// подписанный/временный URL, обновить токен и т.п. Мок-реализация может
  /// просто вернуть `track.audioUrl` синхронно, обёрнутый в Future.
  Future<String> resolveStreamUrl(Track track);

  /// Добавляет трек [trackId] в конец плейлиста [playlistId] (если он там
  /// уже есть — ничего не делает, повторно не дублирует).
  Future<void> addTrackToPlaylist(String playlistId, String trackId);

  /// Убирает трек [trackId] из плейлиста [playlistId] (если его там нет —
  /// ничего не делает).
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId);

  /// Из списка [playlistIds] возвращает те, что уже содержат трек
  /// [trackId] — нужно, чтобы показать галочку в меню "Добавить в
  /// плейлист" и разрешить убрать трек повторным нажатием.
  Future<Set<String>> fetchPlaylistIdsContainingTrack(String trackId, List<String> playlistIds);

  /// Id треков, которые пользователь [userId] отметил как понравившиеся
  /// ("Мои лайкнутые"). То же самое хранилище (`db/favorites.json`),
  /// которое читает и пишет мобильное приложение — поэтому лайк,
  /// поставленный на телефоне, должен появиться и на ПК.
  Future<Set<String>> fetchFavoriteTrackIds(String userId);

  /// Ставит/снимает лайк с трека [trackId] от имени пользователя [userId].
  Future<void> setFavorite({
    required String userId,
    required String trackId,
    required bool favorite,
  });
}
