import '../models/playlist.dart';
import '../models/track.dart';
import 'audio_backend.dart';

/// Мок-реализация [AudioBackend]: отдаёт захардкоженные данные с небольшой
/// искусственной задержкой (имитация сети), чтобы UI сразу вёл себя как
/// с настоящим бэкендом (лоадеры, асинхронность и т.д.).
///
/// Аудио-ссылки — открытые демо-треки (SoundHelix), просто чтобы плеер
/// реально что-то проигрывал "из коробки".
class MockAudioBackend implements AudioBackend {
  static const _networkDelay = Duration(milliseconds: 350);

  static const _demoUrls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
  ];

  late final List<Playlist> _playlists = [
    const Playlist(
      id: 'pl_daily',
      name: 'Daily Mix 1',
      coverUrl: 'https://picsum.photos/seed/daily1/300',
      description: 'Подборка на каждый день',
    ),
    const Playlist(
      id: 'pl_chill',
      name: 'Chill Vibes',
      coverUrl: 'https://picsum.photos/seed/chill/300',
      description: 'Спокойное настроение',
    ),
    const Playlist(
      id: 'pl_focus',
      name: 'Deep Focus',
      coverUrl: 'https://picsum.photos/seed/focus/300',
      description: 'Для концентрации',
    ),
    const Playlist(
      id: 'pl_party',
      name: 'Party Hits',
      coverUrl: 'https://picsum.photos/seed/party/300',
      description: 'Погромче',
    ),
  ];

  late final Map<String, List<Track>> _tracksByPlaylist = {
    'pl_daily': _makeTracks('daily', 'Daily Mix', 6),
    'pl_chill': _makeTracks('chill', 'Chill Vibes', 5),
    'pl_focus': _makeTracks('focus', 'Deep Focus', 5),
    'pl_party': _makeTracks('party', 'Party Hits', 6),
  };

  List<Track> _makeTracks(String seed, String album, int count) {
    final artists = ['Luna Wave', 'Neon Drift', 'Echo Park', 'Silver Fox', 'Aurora Beat'];
    return List.generate(count, (i) {
      final n = i + 1;
      return Track(
        id: '${seed}_$n',
        title: '$album Track $n',
        artist: artists[i % artists.length],
        album: album,
        duration: Duration(minutes: 2 + (i % 3), seconds: 15 * (i % 4)),
        artworkUrl: 'https://picsum.photos/seed/$seed$n/300',
        audioUrl: _demoUrls[(i + seed.length) % _demoUrls.length],
      );
    });
  }

  @override
  Future<List<Playlist>> fetchPlaylists(String? userId) async {
    await Future.delayed(_networkDelay);
    return _playlists;
  }

  @override
  Future<List<Track>> fetchTracksForPlaylist(String playlistId) async {
    await Future.delayed(_networkDelay);
    return _tracksByPlaylist[playlistId] ?? const [];
  }

  @override
  Future<List<Track>> fetchAllTracks() async {
    await Future.delayed(_networkDelay);
    return _tracksByPlaylist.values.expand((list) => list).toList();
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    await Future.delayed(_networkDelay);
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];
    return _tracksByPlaylist.values
        .expand((list) => list)
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<String> resolveStreamUrl(Track track) async {
    // В реальном бэкенде тут мог бы быть запрос за временным подписанным URL.
    return track.audioUrl;
  }

  @override
  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    await Future.delayed(_networkDelay);
    final list = _tracksByPlaylist[playlistId];
    if (list == null) {
      throw StateError('Playlist $playlistId not found');
    }
    if (list.any((t) => t.id == trackId)) return;
    final track = _tracksByPlaylist.values.expand((l) => l).firstWhere((t) => t.id == trackId);
    list.add(track);
  }

  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    await Future.delayed(_networkDelay);
    _tracksByPlaylist[playlistId]?.removeWhere((t) => t.id == trackId);
  }

  @override
  Future<Set<String>> fetchPlaylistIdsContainingTrack(String trackId, List<String> playlistIds) async {
    await Future.delayed(_networkDelay);
    return {
      for (final id in playlistIds)
        if (_tracksByPlaylist[id]?.any((t) => t.id == trackId) ?? false) id,
    };
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await Future.delayed(_networkDelay);
    _playlists.removeWhere((p) => p.id == playlistId);
    _tracksByPlaylist.remove(playlistId);
  }

  @override
  Future<Playlist> renamePlaylist(String playlistId, String newName) async {
    await Future.delayed(_networkDelay);
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) {
      throw StateError('Playlist $playlistId not found');
    }
    final updated = Playlist(
      id: _playlists[index].id,
      name: newName,
      coverUrl: _playlists[index].coverUrl,
      description: _playlists[index].description,
      isVirtual: _playlists[index].isVirtual,
    );
    _playlists[index] = updated;
    return updated;
  }

  // userId -> набор id лайкнутых треков. Просто в памяти — мок не должен
  // изображать настоящее хранилище, только не ломать интерфейс.
  final Map<String, Set<String>> _favoritesByUser = {};

  @override
  Future<Set<String>> fetchFavoriteTrackIds(String userId) async {
    await Future.delayed(_networkDelay);
    return Set.of(_favoritesByUser[userId] ?? const {});
  }

  @override
  Future<void> setFavorite({required String userId, required String trackId, required bool favorite}) async {
    await Future.delayed(_networkDelay);
    final set = _favoritesByUser.putIfAbsent(userId, () => <String>{});
    if (favorite) {
      set.add(trackId);
    } else {
      set.remove(trackId);
    }
  }
}
