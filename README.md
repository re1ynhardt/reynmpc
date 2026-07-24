# Fluttify — аудиоплеер в стиле Spotify (desktop)

Flutter-приложение с UI как у десктопного клиента Spotify: сайдбар с
плейлистами, список треков, нижний бар плеера с прогрессом и громкостью.

Вся логика получения данных спрятана за одним интерфейсом — `AudioBackend`.
Реальное воспроизведение аудио идёт через `just_audio` и не зависит от
того, откуда взялся URL трека.

## Запуск

```bash
flutter pub get
flutter run -d windows   # или -d macos / -d linux / -d chrome
```

Сейчас используется `MockAudioBackend` с тестовыми данными (обложки —
picsum.photos, треки — открытые демо-mp3 SoundHelix), чтобы плеер сразу
что-то реально проигрывал.

## Подключение Yandex Object Storage (то же хранилище, что в мобильном приложении)

Уже готова реализация `YandexStorageAudioBackend` — она читает из вашего
бакета через S3-совместимое API (пакет `minio`).

**Шаг 1.** Вставьте ключи доступа в `lib/backend/yandex_storage_config.dart`:

```dart
const yandexStorageConfig = YandexStorageConfig(
  bucket: 'мой-бакет',
  accessKey: 'YCxxxxxxxxxxxxxxxxxxxx',
  secretKey: 'YCxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
);
```

**Шаг 2.** В `lib/main.dart` раскомментируйте импорты и поменяйте одну строку:

```dart
runApp(SpotifyCloneApp(backend: YandexStorageAudioBackend(yandexStorageConfig)));
```

Больше ничего менять не нужно — весь UI и плеер продолжат работать как есть.

### Какую структуру бакета ожидает бэкенд

```
metadata/playlists.json   — список плейлистов
metadata/tracks.json      — список всех треков
audio/*.mp3                — сами файлы треков
covers/*.jpg                — обложки
```

Примеры файлов — в `example_data/playlists.json` и `example_data/tracks.json`.
Ссылки на аудио и обложки резолвятся в presigned URL (временную подписанную
ссылку) прямо из бэкенда — это работает даже с приватным бакетом.

**Если в мобильном приложении метаданные организованы иначе** (не JSON-манифест
в бакете, а, например, отдельная база/API) — поменяйте только тело
`fetchPlaylists()` и `_allTracks()` внутри
`lib/backend/yandex_storage_audio_backend.dart`, чтобы они брали данные из
вашего реального источника. Логику самого Object Storage (presigned URL на
аудио и обложки) трогать не придётся.

## Как подключить свой бэкенд (одна строка)

Всё, что нужно — реализовать интерфейс `AudioBackend`
(`lib/backend/audio_backend.dart`):

```dart
abstract class AudioBackend {
  Future<List<Playlist>> fetchPlaylists();
  Future<List<Track>> fetchTracksForPlaylist(String playlistId);
  Future<List<Track>> searchTracks(String query);
  Future<String> resolveStreamUrl(Track track);
}
```

Например, REST-бэкенд:

```dart
class RestAudioBackend implements AudioBackend {
  RestAudioBackend(this.baseUrl);
  final String baseUrl;

  @override
  Future<List<Playlist>> fetchPlaylists() async {
    final res = await http.get(Uri.parse('$baseUrl/playlists'));
    return (jsonDecode(res.body) as List).map((e) => Playlist(...)).toList();
  }
  // ...остальные методы
}
```

И затем в `lib/main.dart` меняете ровно одну строку:

```dart
void main() {
  runApp(SpotifyCloneApp(backend: RestAudioBackend('https://api.example.com')));
  //                                ^^^^^^^^^^^^^^^ было MockAudioBackend()
}
```

Всё остальное приложение (UI, плеер, состояние) переподключится к новому
источнику данных автоматически — они работают только через интерфейс
`AudioBackend` и ничего не знают о конкретной реализации.

## Структура проекта

```
lib/
  backend/
    audio_backend.dart               # контракт бэкенда
    mock_audio_backend.dart          # мок-реализация
    yandex_storage_config.dart       # 👈 сюда вставляете ключи доступа
    yandex_storage_audio_backend.dart # реализация поверх Yandex Object Storage
  models/
    track.dart
    playlist.dart
    nav_view.dart
  library/
    music_library.dart        # состояние каталога (плейлисты/треки/поиск)
  player/
    player_controller.dart    # обёртка над just_audio, очередь, shuffle/repeat
  localization/
    app_language.dart
    app_strings.dart
    locale_controller.dart    # текущий язык интерфейса (RU/EN)
  widgets/
    sidebar.dart
    player_bar.dart
    track_list_view.dart
    library_grid_view.dart
    settings_dialog.dart
  screens/
    home_screen.dart
  theme/
    app_theme.dart
  main.dart                   # точка входа + подключение бэкенда
example_data/
  playlists.json               # пример манифеста плейлистов
  tracks.json                  # пример манифеста треков
```
