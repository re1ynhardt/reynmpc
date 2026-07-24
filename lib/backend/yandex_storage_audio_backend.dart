import 'dart:convert';

import 'package:minio/minio.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import 'audio_backend.dart';
import 'yandex_storage_config.dart';

/// Бэкенд поверх Yandex Object Storage (S3-совместимое API) — то же
/// хранилище, что уже используется в мобильном приложении.
///
/// КАК ЭТО РАБОТАЕТ
/// Метаданные (плейлисты, треки) хранятся как два JSON-файла в бакете,
/// а сами mp3 и обложки — как обычные объекты. Ссылки на объекты
/// получаются через presigned URL (временная подписанная ссылка,
/// работает и для приватного бакета).
///
/// ОЖИДАЕМАЯ СТРУКТУРА БАКЕТА (поправьте под свою — см. TODO ниже,
/// если в мобильном приложении структура отличается):
///
///   metadata/playlists.json
///     [{ "id": "pl_daily", "name": "Daily Mix", "cover": "covers/daily.jpg", "description": "..." }, ...]
///
///   metadata/tracks.json
///     [{
///        "id": "t1", "title": "...", "artist": "...", "album": "...",
///        "durationSec": 215, "cover": "covers/t1.jpg", "audioKey": "audio/t1.mp3",
///        "playlistIds": ["pl_daily", "pl_chill"]
///     }, ...]
///
///   audio/*.mp3   — сами файлы треков
///   covers/*.jpg  — обложки
///
/// Если у вас в мобильном приложении метаданные организованы иначе
/// (например, в отдельной базе, а не в JSON внутри бакета) — замените
/// тело fetchPlaylists()/_allTracks() на запрос к своему источнику
/// метаданных; работа с самим Object Storage (presigned URL на аудио)
/// при этом останется прежней.
class YandexStorageAudioBackend implements AudioBackend {
  YandexStorageAudioBackend(this.config)
      : _minio = Minio(
          endPoint: config.endpoint,
          accessKey: config.accessKey,
          secretKey: config.secretKey,
          region: config.region,
          useSSL: config.useSSL,
        );

  final YandexStorageConfig config;
  final Minio _minio;

  List<Playlist>? _playlistsCache;
  List<Track>? _tracksCache;

  // ---- низкоуровневые хелперы для чтения объектов из бакета ----

  Future<String> _readObjectAsString(String key) async {
    final stream = await _minio.getObject(config.bucket, key);
    final bytes = await stream.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
    return utf8.decode(bytes);
  }

  /// Превращает ключ объекта ("audio/t1.mp3", "covers/t1.jpg") во
  /// временную подписанную ссылку, по которой можно скачать/проиграть файл.
  Future<String> _presignedUrl(String objectKey, {int expiresSeconds = 3600}) {
    return _minio.presignedGetObject(config.bucket, objectKey, expires: expiresSeconds);
  }

  // ---- реализация AudioBackend ----

  @override
  Future<List<Playlist>> fetchPlaylists() async {
    if (_playlistsCache != null) return _playlistsCache!;

    final raw = await _readObjectAsString('metadata/playlists.json');
    final items = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    _playlistsCache = await Future.wait(items.map((json) async {
      final coverKey = json['cover'] as String? ?? '';
      return Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        // Обложки резолвим сразу — они нужны в UI немедленно.
        // Обложки живут дольше (24ч), чем ссылки на аудио, чтобы не
        // ловить битые картинки в длинных сессиях.
        coverUrl: coverKey.isEmpty ? '' : await _presignedUrl(coverKey, expiresSeconds: 60 * 60 * 24),
        description: json['description'] as String? ?? '',
      );
    }));

    return _playlistsCache!;
  }

  Future<List<_TrackManifestEntry>> _allTrackEntries() async {
    final raw = await _readObjectAsString('metadata/tracks.json');
    final items = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return items.map(_TrackManifestEntry.fromJson).toList();
  }

  Future<List<Track>> _allTracks() async {
    if (_tracksCache != null) return _tracksCache!;

    final entries = await _allTrackEntries();
    _tracksCache = await Future.wait(entries.map((e) async {
      return Track(
        id: e.id,
        title: e.title,
        artist: e.artist,
        album: e.album,
        duration: Duration(seconds: e.durationSec),
        artworkUrl: e.coverKey.isEmpty ? '' : await _presignedUrl(e.coverKey, expiresSeconds: 60 * 60 * 24),
        // audioUrl тут хранит КЛЮЧ объекта, а не готовую ссылку — сама
        // ссылка резолвится лениво в resolveStreamUrl() непосредственно
        // перед воспроизведением, чтобы не протухала.
        audioUrl: e.audioKey,
      );
    }));

    return _tracksCache!;
  }

  @override
  Future<List<Track>> fetchTracksForPlaylist(String playlistId) async {
    final entries = await _allTrackEntries();
    final matchingIds = entries.where((e) => e.playlistIds.contains(playlistId)).map((e) => e.id).toSet();
    final all = await _allTracks();
    return all.where((t) => matchingIds.contains(t.id)).toList();
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];
    final all = await _allTracks();
    return all
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<String> resolveStreamUrl(Track track) async {
    // track.audioUrl здесь — это ключ объекта (см. _allTracks), поэтому
    // резолвим его в свежую подписанную ссылку прямо перед стартом плеера.
    return _presignedUrl(track.audioUrl, expiresSeconds: 3600);
  }
}

class _TrackManifestEntry {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationSec;
  final String coverKey;
  final String audioKey;
  final List<String> playlistIds;

  _TrackManifestEntry({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSec,
    required this.coverKey,
    required this.audioKey,
    required this.playlistIds,
  });

  factory _TrackManifestEntry.fromJson(Map<String, dynamic> json) {
    return _TrackManifestEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String? ?? '',
      durationSec: json['durationSec'] as int? ?? 0,
      coverKey: json['cover'] as String? ?? '',
      audioKey: json['audioKey'] as String,
      playlistIds: (json['playlistIds'] as List?)?.cast<String>() ?? const [],
    );
  }
}
