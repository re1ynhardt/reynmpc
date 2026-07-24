import 'package:flutter/foundation.dart';

import '../backend/audio_backend.dart';
import '../models/playlist.dart';
import '../models/track.dart';

/// Держит состояние каталога (плейлисты, треки текущего плейлиста,
/// результаты поиска) и дергает [AudioBackend] за данными.
/// UI никогда не обращается к бэкенду напрямую — только через этот класс.
class MusicLibrary extends ChangeNotifier {
  MusicLibrary(this._backend) {
    _loadPlaylists();
  }

  final AudioBackend _backend;

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

  // Лайкнутые треки храним прямо здесь (id -> трек), а не только id,
  // чтобы собрать плейлист "Мои лайкнутые" без похода в бэкенд —
  // трек мог прийти из любого плейлиста или из поиска.
  final Map<String, Track> _likedTracks = {};

  List<Track> get likedTracks => _likedTracks.values.toList(growable: false);

  bool isLiked(Track track) => _likedTracks.containsKey(track.id);

  void toggleLike(Track track) {
    if (_likedTracks.containsKey(track.id)) {
      _likedTracks.remove(track.id);
    } else {
      _likedTracks[track.id] = track;
    }
    // Если сейчас открыт сам плейлист лайков — обновляем его список треков
    // тут же, без повторного похода в selectPlaylist.
    if (selectedPlaylist?.id == likedPlaylistId) {
      tracksOfSelectedPlaylist = likedTracks;
    }
    notifyListeners();
  }

  Future<void> _loadPlaylists() async {
    isLoadingPlaylists = true;
    notifyListeners();
    final fetched = await _backend.fetchPlaylists();
    // "Мои лайкнутые" всегда первым пунктом в медиатеке, как в Spotify.
    playlists = [likedPlaylist, ...fetched];
    isLoadingPlaylists = false;
    if (fetched.isNotEmpty) {
      await selectPlaylist(fetched.first);
    } else {
      notifyListeners();
    }
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

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    searchResults = await _backend.searchTracks(query);
    isSearching = false;
    notifyListeners();
  }
}
