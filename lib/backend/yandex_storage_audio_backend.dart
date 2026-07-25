import 'dart:convert';

import 'package:minio/minio.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import 'audio_backend.dart';
import 'yandex_storage_config.dart';

/// Бэкенд поверх Yandex Object Storage (S3-совместимое API) — то же самое
/// хранилище (и та же "база данных" в виде JSON-файлов в бакете), что уже
/// используется мобильным приложением. ПК-версия ничего не создаёт заново —
/// она читает и аккуратно обновляет те же объекты.
///
/// РЕАЛЬНАЯ СТРУКТУРА БАКЕТА (как в мобильном приложении):
///
///   db/playlists.json
///     { "items": [
///         { "id": "...", "owner_id": "...", "name": "...",
///           "cover_url": "https://.../media/covers/....jpg" (может быть ""),
///           "track_ids": ["...", "..."] },
///         ...
///     ] }
///
///   db/tracks.json
///     { "items": [
///         { "id": "...", "title": "...", "artist": "...", "album": "...",
///           "cover_url": "https://.../media/covers/....jpg",
///           "audio_url": "https://.../media/audio/....mp3",
///           "duration_seconds": 215,
///           "uploaded_locally": true, "uploader_id": "...", "created_at": 0.0 },
///         ...
///     ] }
///
/// Важно: `cover_url` и `audio_url` в этой схеме — это уже ГОТОВЫЕ прямые
/// ссылки (медиа лежит в публично читаемой части бакета), а не ключи
/// объектов. Поэтому, в отличие от черновой версии этого файла, здесь НЕ
/// нужен пресайнинг для аудио/обложек — они используются как есть.
/// Приватность нужна только для самих db/*.json (там есть служебные поля
/// вроде uploader_id), поэтому их мы по-прежнему читаем/пишем через Minio
/// с access/secret key.
///
/// db/users.json, db/favorites.json, db/favorite_users.json и т.п. этот
/// бэкенд не трогает — авторизация в ПК-версии сейчас отдельная, локальная
/// (см. lib/auth/auth_controller.dart), чтобы ничего не сломать. Если
/// позже понадобится завести реальный вход по той же базе пользователей —
/// это отдельная задача (нужно знать точный алгоритм хеширования пароля,
/// которым пользуется мобильное приложение/бэкенд, иначе есть риск либо
/// пустить не туда, либо запереть существующих пользователей).
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

  static const _playlistsKey = 'db/playlists.json';
  static const _tracksKey = 'db/tracks.json';
  static const _favoritesKey = 'db/favorites.json';

  List<Playlist>? _playlistsCache;
  // Сырые записи плейлистов (с track_ids, owner_id и т.д.) — нужны отдельно
  // от [Playlist], т.к. модель приложения не хранит track_ids/owner_id, а
  // при переименовании/удалении мы не должны терять эти поля в бакете.
  List<Map<String, dynamic>>? _rawPlaylistsCache;

  List<Track>? _tracksCache;
  Map<String, Track>? _tracksByIdCache;

  // ---- низкоуровневые хелперы для чтения/записи JSON-объектов в бакете ----

  Future<String> _readObjectAsString(String key) async {
    final stream = await _minio.getObject(config.bucket, key);
    final bytes = await stream.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
    return utf8.decode(bytes);
  }

  Future<void> _writeJsonObject(String key, Object value) async {
    final bytes = utf8.encode(jsonEncode(value));
    await _minio.putObject(config.bucket, key, Stream.value(bytes));
  }

  // ---- чтение треков ----

  Track _trackFromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      duration: Duration(seconds: (json['duration_seconds'] as num? ?? 0).toInt()),
      artworkUrl: json['cover_url'] as String? ?? '',
      // Уже готовая прямая ссылка на mp3 — presigned URL здесь не нужен,
      // см. resolveStreamUrl ниже.
      audioUrl: json['audio_url'] as String? ?? '',
    );
  }

  Future<List<Track>> _allTracks() async {
    if (_tracksCache != null) return _tracksCache!;

    final raw = await _readObjectAsString(_tracksKey);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List).cast<Map<String, dynamic>>();

    final tracks = items.map(_trackFromJson).toList();
    _tracksCache = tracks;
    _tracksByIdCache = {for (final t in tracks) t.id: t};
    return tracks;
  }

  // ---- чтение плейлистов ----

  Playlist _playlistFromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      // В реальной схеме у плейлиста нет отдельного описания.
      description: '',
    );
  }

  Future<List<Map<String, dynamic>>> _rawPlaylists() async {
    if (_rawPlaylistsCache != null) return _rawPlaylistsCache!;

    final raw = await _readObjectAsString(_playlistsKey);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List).cast<Map<String, dynamic>>();
    _rawPlaylistsCache = items;
    return items;
  }

  // ---- реализация AudioBackend ----

  @override
  Future<List<Playlist>> fetchPlaylists() async {
    if (_playlistsCache != null) return _playlistsCache!;

    final items = await _rawPlaylists();
    _playlistsCache = items.map(_playlistFromJson).toList();
    return _playlistsCache!;
  }

  @override
  Future<List<Track>> fetchTracksForPlaylist(String playlistId) async {
    final items = await _rawPlaylists();
    final playlistJson = items.firstWhere(
      (p) => p['id'] == playlistId,
      orElse: () => const {},
    );
    final trackIds = (playlistJson['track_ids'] as List?)?.cast<String>() ?? const [];

    await _allTracks();
    final byId = _tracksByIdCache!;

    // Порядок треков в плейлисте важен — сохраняем его как в track_ids,
    // пропуская id, для которых трека почему-то не нашлось в tracks.json.
    return trackIds.map((id) => byId[id]).whereType<Track>().toList();
  }

  @override
  Future<List<Track>> fetchAllTracks() => _allTracks();

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
    // track.audioUrl здесь — уже готовая прямая ссылка (см. _trackFromJson),
    // поэтому просто возвращаем её как есть, без похода в S3 за подписью.
    return track.audioUrl;
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    // Удаляем только запись о плейлисте из db/playlists.json — сами треки
    // (db/tracks.json) и медиафайлы в бакете не трогаем, т.к. треки могут
    // входить в другие плейлисты и использоваться мобильным приложением.
    final items = List<Map<String, dynamic>>.from(await _rawPlaylists());
    items.removeWhere((json) => json['id'] == playlistId);

    await _writeJsonObject(_playlistsKey, {'items': items});

    _rawPlaylistsCache = null;
    _playlistsCache = null;
  }

  @override
  Future<Playlist> renamePlaylist(String playlistId, String newName) async {
    final items = List<Map<String, dynamic>>.from(await _rawPlaylists());

    final index = items.indexWhere((json) => json['id'] == playlistId);
    if (index == -1) {
      throw StateError('Playlist $playlistId not found');
    }
    // Спред сохраняет все существующие поля (owner_id, track_ids,
    // cover_url и т.п.) — меняется только name, остальное как было и в
    // мобильном приложении.
    items[index] = {...items[index], 'name': newName};

    await _writeJsonObject(_playlistsKey, {'items': items});

    _rawPlaylistsCache = null;
    _playlistsCache = null;

    return _playlistFromJson(items[index]);
  }

  // ---- избранное ("Мои лайкнутые") ----------------------------------
  //
  // db/favorites.json — плоский список пар {user_id, track_id}, ровно та
  // же схема, что и в мобильном приложении (см.
  // lib/services/yandex_storage_api_service.dart -> fetchFavoriteIds /
  // setFavorite), поэтому лайки видны на обеих версиях одинаково.

  List<Map<String, dynamic>>? _rawFavoritesCache;

  Future<List<Map<String, dynamic>>> _rawFavorites() async {
    if (_rawFavoritesCache != null) return _rawFavoritesCache!;
    final raw = await _readObjectAsString(_favoritesKey);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List).cast<Map<String, dynamic>>();
    _rawFavoritesCache = items;
    return items;
  }

  @override
  Future<Set<String>> fetchFavoriteTrackIds(String userId) async {
    final items = await _rawFavorites();
    return items.where((r) => r['user_id'] == userId).map((r) => r['track_id'] as String).toSet();
  }

  @override
  Future<void> setFavorite({
    required String userId,
    required String trackId,
    required bool favorite,
  }) async {
    final items = List<Map<String, dynamic>>.from(await _rawFavorites());
    final exists = items.any((r) => r['user_id'] == userId && r['track_id'] == trackId);

    if (favorite && !exists) {
      items.add({'user_id': userId, 'track_id': trackId});
    } else if (!favorite && exists) {
      items.removeWhere((r) => r['user_id'] == userId && r['track_id'] == trackId);
    } else {
      return; // уже в нужном состоянии — лишний запрос на запись не нужен
    }

    await _writeJsonObject(_favoritesKey, {'items': items});
    _rawFavoritesCache = items;
  }
}
