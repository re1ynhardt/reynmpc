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

  List<Playlist> playlists = [];
  bool isLoadingPlaylists = true;

  Playlist? selectedPlaylist;
  List<Track> tracksOfSelectedPlaylist = [];
  bool isLoadingTracks = false;

  List<Track> searchResults = [];
  bool isSearching = false;

  Future<void> _loadPlaylists() async {
    isLoadingPlaylists = true;
    notifyListeners();
    playlists = await _backend.fetchPlaylists();
    isLoadingPlaylists = false;
    if (playlists.isNotEmpty) {
      await selectPlaylist(playlists.first);
    } else {
      notifyListeners();
    }
  }

  Future<void> selectPlaylist(Playlist playlist) async {
    selectedPlaylist = playlist;
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
