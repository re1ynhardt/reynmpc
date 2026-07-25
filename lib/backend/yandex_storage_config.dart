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
/// bucket уже подставлен — это имя видно в прямых ссылках на медиа
/// (cover_url/audio_url) в ваших же данных, то же хранилище, что и в
/// мобильном приложении. А вот accessKey/secretKey — секретные, их тут
/// нет и не может быть: впишите те же значения, что использует мобильное
/// приложение / его бэкенд.
///
/// После заполнения ключей бэкенд уже подключён в lib/main.dart.
const yandexStorageConfig = YandexStorageConfig(
  bucket: 'storagereyg',
  accessKey: 'YCAJE0POvQbcWw9VSrNflht9s',
  secretKey: 'YCMtrMWWbFX6UB-_dO4VuNa2cAnIBZJvemoAkWic',
);
