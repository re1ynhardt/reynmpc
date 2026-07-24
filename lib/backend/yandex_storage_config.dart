/// Данные доступа к Yandex Object Storage.
///
/// Это ЕДИНСТВЕННОЕ место, которое нужно поменять, чтобы подключить
/// то же хранилище, что уже используется в мобильном приложении.
/// Просто вставьте сюда свои значения ↓
class YandexStorageConfig {
  /// S3-эндпоинт Yandex Object Storage. Обычно менять не нужно.
  final String endpoint;

  /// Регион бакета. Обычно менять не нужно.
  final String region;

  /// Имя бакета, где лежат треки/обложки/метаданные.
  final String bucket;

  /// Ключи доступа (Access key / Secret key) — те же, что вшиты в
  /// мобильном приложении.
  final String accessKey;
  final String secretKey;

  final bool useSSL;

  const YandexStorageConfig({
    this.endpoint = 'storage.yandexcloud.net',
    this.region = 'ru-central1',
    required this.bucket,
    required this.accessKey,
    required this.secretKey,
    this.useSSL = true,
  });
}

/// 👇 ВСТАВЬТЕ СВОИ ДАННЫЕ СЮДА
///
/// После заполнения подключите бэкенд в lib/main.dart, поменяв одну строку:
///
///   runApp(SpotifyCloneApp(backend: YandexStorageAudioBackend(yandexStorageConfig)));
///
const yandexStorageConfig = YandexStorageConfig(
  bucket: 'PASTE_BUCKET_NAME_HERE',
  accessKey: 'PASTE_ACCESS_KEY_HERE',
  secretKey: 'PASTE_SECRET_KEY_HERE',
);
