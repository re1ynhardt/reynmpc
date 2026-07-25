import 'package:flutter/foundation.dart';

import '../backend/audio_backend.dart';
import '../models/playlist.dart';
import '../models/track.dart';

/// Держит состояние каталога (плейлисты, треки текущего плейлиста,
/// результаты поиска) и дергает [AudioBackend] за данными.
/// UI никогда не обращается к бэкенду напрямую — только через этот класс.
class MusicLibrary extends ChangeNotifier {
  MusicLibrary(this._backend) {
    _loadAllTracks();
  }

  final AudioBackend _backend;

  /// Сколько треков показываем на Главной.
  static const homeTracksLimit = 100;

  /// Максимум треков, показываемых в результатах поиска.
  static const searchResultsLimit = 50;

  /// Специальная клиентская библиотека со всеми лайкнутыми треками —
  /// это НЕ плейлист (у неё нет привычных плейлисту атрибутов вроде
  /// порядка треков, обложки или владельца), а отдельная сущность.
  /// Существует только на клиенте — бэкенд про неё ничего не знает,
  /// её треки собираются из [_likedTracks].
  ///
  /// [Playlist.name] и [Playlist.description] здесь — не более чем
  /// технические заглушки на случай прямого обращения к полю: реальное,
  /// локализованное на оба языка название и описание отображаются через
  /// AppStrings.likedLibraryName / likedLibraryDescription в местах
  /// вывода на экран (см. home_screen.dart, library_grid_view.dart) —
  /// эта библиотека не должна иметь единственного зашитого имени.
  static const likedPlaylistId = '__liked__';
  static const Playlist likedPlaylist = Playlist(
    id: likedPlaylistId,
    name: '',
    coverUrl: '',
    description: '',
    isVirtual: true,
  );

  List<Playlist> playlists = [];
  bool isLoadingPlaylists = true;

  Playlist? selectedPlaylist;
  List<Track> tracksOfSelectedPlaylist = [];
  bool isLoadingTracks = false;

  List<Track> searchResults = [];
  bool isSearching = false;

  // Все треки, загруженные в плеер — источник для Главной.
  List<Track> allTracks = [];
  bool isLoadingAllTracks = true;

  /// Первые [homeTracksLimit] треков из [allTracks] — то, что показывается
  /// на Главной по умолчанию (пока не открыт конкретный плейлист).
  List<Track> get homeTracks => allTracks.length > homeTracksLimit
      ? allTracks.sublist(0, homeTracksLimit)
      : allTracks;

  // Лайкнутые треки храним прямо здесь (id -> трек), а не только id,
  // чтобы собрать плейлист "Мои лайкнутые" без похода в бэкенд —
  // трек мог прийти из любого плейлиста или из поиска.
  final Map<String, Track> _likedTracks = {};

  // Id текущего пользователя (см. AuthController.currentUserId) — нужен,
  // чтобы знать, чьи лайки грузить/сохранять на сервере. Пока пользователь
  // не известен (не залогинен), лайки существуют только локально в этой
  // сессии и никуда не сохраняются.
  String? _currentUserId;

  List<Track> get likedTracks => _likedTracks.values.toList(growable: false);

  bool isLiked(Track track) => _likedTracks.containsKey(track.id);

  /// Вызывается при входе/выходе из аккаунта (см. AuthGate в main.dart).
  /// Подтягивает с сервера id лайкнутых треков этого пользователя и
  /// сопоставляет их с уже загруженным каталогом ([allTracks]) — если
  /// каталог ещё не успел загрузиться, дожидается его.
  Future<void> loadFavoritesForUser(String? userId) async {
    _currentUserId = userId;
    _likedTracks.clear();

    if (userId == null) {
      if (selectedPlaylist?.id == likedPlaylistId) tracksOfSelectedPlaylist = likedTracks;
      notifyListeners();
      return;
    }

    final ids = await _backend.fetchFavoriteTrackIds(userId);
    if (ids.isEmpty) {
      notifyListeners();
      return;
    }

    // Лайкнутый трек мог быть не среди allTracks (например, если каталог
    // ещё грузится) — дожидаемся его, чтобы не потерять лайки молча.
    while (isLoadingAllTracks) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final byId = {for (final t in allTracks) t.id: t};
    for (final id in ids) {
      final track = byId[id];
      if (track != null) _likedTracks[id] = track;
    }

    if (selectedPlaylist?.id == likedPlaylistId) tracksOfSelectedPlaylist = likedTracks;
    notifyListeners();
  }

  void toggleLike(Track track) {
    final liked = !_likedTracks.containsKey(track.id);
    if (liked) {
      _likedTracks[track.id] = track;
    } else {
      _likedTracks.remove(track.id);
    }
    // Если сейчас открыт сам плейлист лайков — обновляем его список треков
    // тут же, без повторного похода в selectPlaylist.
    if (selectedPlaylist?.id == likedPlaylistId) {
      tracksOfSelectedPlaylist = likedTracks;
    }
    notifyListeners();

    // Сохраняем на сервере в фоне — UI не ждёт сети. Если пользователь не
    // залогинен (userId ещё не известен), лайк остаётся только локальным
    // на эту сессию, как и раньше.
    final userId = _currentUserId;
    if (userId != null) {
      _backend.setFavorite(userId: userId, trackId: track.id, favorite: liked);
    }
  }

  /// Вызывается при входе/выходе из аккаунта (см. AuthGate в main.dart),
  /// как и [loadFavoritesForUser] — иначе после смены пользователя в
  /// медиатеке продолжали бы висеть плейлисты предыдущего аккаунта.
  Future<void> loadPlaylistsForUser(String? userId) async {
    isLoadingPlaylists = true;
    notifyListeners();
    final fetched = await _backend.fetchPlaylists(userId);
    // "Мои лайкнутые" всегда первым пунктом в медиатеке, как в Spotify.
    playlists = [likedPlaylist, ...fetched];
    isLoadingPlaylists = false;
    if (selectedPlaylist != null && selectedPlaylist!.id != likedPlaylistId &&
        !playlists.any((p) => p.id == selectedPlaylist!.id)) {
      // Открытый плейлист принадлежал предыдущему пользователю — закрываем.
      selectedPlaylist = null;
      tracksOfSelectedPlaylist = [];
    }
    // Плейлист больше не выбирается автоматически — по умолчанию Главная
    // показывает первые [homeTracksLimit] всех треков (см. [homeTracks]).
    notifyListeners();
  }

  Future<void> _loadAllTracks() async {
    isLoadingAllTracks = true;
    notifyListeners();
    allTracks = await _backend.fetchAllTracks();
    isLoadingAllTracks = false;
    notifyListeners();
  }

  /// Сбрасывает выбранный плейлист — используется при возврате на Главную,
  /// чтобы снова показать общий список первых треков вместо плейлиста.
  void clearSelectedPlaylist() {
    if (selectedPlaylist == null) return;
    selectedPlaylist = null;
    tracksOfSelectedPlaylist = [];
    notifyListeners();
  }

  Future<void> selectPlaylist(Playlist playlist) async {
    selectedPlaylist = playlist;
    if (playlist.id == likedPlaylistId) {
      // Виртуальный плейлист — треки уже есть на клиенте, в бэкенд не идём.
      isLoadingTracks = false;
      tracksOfSelectedPlaylist = likedTracks;
      notifyListeners();
      return;
    }
    isLoadingTracks = true;
    notifyListeners();
    tracksOfSelectedPlaylist = await _backend.fetchTracksForPlaylist(playlist.id);
    isLoadingTracks = false;
    notifyListeners();
  }

  /// Переименовывает плейлист (кроме виртуальной библиотеки лайкнутых,
  /// у которой нет собственного имени на бэкенде — см. [likedPlaylist]).
  Future<void> renamePlaylist(Playlist playlist, String newName) async {
    final trimmed = newName.trim();
    if (playlist.isVirtual || trimmed.isEmpty || trimmed == playlist.name) return;

    final updated = await _backend.renamePlaylist(playlist.id, trimmed);

    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) playlists[index] = updated;

    if (selectedPlaylist?.id == playlist.id) selectedPlaylist = updated;

    notifyListeners();
  }

  /// Удаляет плейлист (кроме виртуальной библиотеки лайкнутых).
  Future<void> deletePlaylist(Playlist playlist) async {
    if (playlist.isVirtual) return;

    await _backend.deletePlaylist(playlist.id);

    playlists.removeWhere((p) => p.id == playlist.id);
    if (selectedPlaylist?.id == playlist.id) {
      selectedPlaylist = null;
      tracksOfSelectedPlaylist = [];
    }

    notifyListeners();
  }

  /// Добавляет трек в плейлист (кроме виртуальной библиотеки лайкнутых —
  /// туда попадают только через [toggleLike]). Если этот плейлист сейчас
  /// открыт — сразу дописывает трек в отображаемый список, не дожидаясь
  /// повторного похода в бэкенд.
  Future<void> addTrackToPlaylist(Track track, Playlist playlist) async {
    if (playlist.isVirtual) return;

    await _backend.addTrackToPlaylist(playlist.id, track.id);

    if (selectedPlaylist?.id == playlist.id && !tracksOfSelectedPlaylist.any((t) => t.id == track.id)) {
      tracksOfSelectedPlaylist = [...tracksOfSelectedPlaylist, track];
      notifyListeners();
    }
  }

  /// Убирает трек из плейлиста — используется для повторного нажатия в
  /// меню "Добавить в плейлист" (см. [playlistIdsContainingTrack]).
  Future<void> removeTrackFromPlaylist(Track track, Playlist playlist) async {
    if (playlist.isVirtual) return;

    await _backend.removeTrackFromPlaylist(playlist.id, track.id);

    if (selectedPlaylist?.id == playlist.id) {
      tracksOfSelectedPlaylist = tracksOfSelectedPlaylist.where((t) => t.id != track.id).toList();
      notifyListeners();
    }
  }

  /// Из списка [playlists] возвращает id тех, что уже содержат [track] —
  /// чтобы меню "Добавить в плейлист" могло показать галочку и переключать
  /// добавление/удаление повторным нажатием.
  Future<Set<String>> playlistIdsContainingTrack(Track track, List<Playlist> playlists) {
    final ids = playlists.where((p) => !p.isVirtual).map((p) => p.id).toList();
    return _backend.fetchPlaylistIdsContainingTrack(track.id, ids);
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    final results = await _backend.searchTracks(query);
    searchResults =
        results.length > searchResultsLimit ? results.sublist(0, searchResultsLimit) : results;
    isSearching = false;
    notifyListeners();
  }
}
