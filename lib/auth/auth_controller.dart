import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Результат попытки входа/регистрации — удобно возвращать причину отказа,
/// чтобы экран авторизации мог показать понятную ошибку.
enum AuthResult {
  success,
  userNotFound,
  wrongPassword,
  userAlreadyExists,
  invalidEmail,
  invalidInput,
}

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Те же учётные данные Yandex Object Storage, что и в мобильной версии
/// (lib/main.dart мобильного проекта) — оба приложения читают и пишут
/// один и тот же бакет, поэтому аккаунт, созданный на телефоне, сразу
/// доступен на ПК и наоборот.
class _YandexConfig {
  static const accessKeyId = 'YCAJE0POvQbcWw9VSrNflht9s';
  static const secretAccessKey = 'YCMtrMWWbFX6UB-_dO4VuNa2cAnIBZJvemoAkWic';
  static const bucket = 'storagereyg';
  static const endpointHost = 'storage.yandexcloud.net';
  static const region = 'ru-central1';
}

/// Минимальный подписчик запросов AWS Signature V4, идентичный тому, что
/// использует мобильная версия (lib/services/yandex_sigv4.dart) — нужен,
/// чтобы обращаться напрямую к S3-совместимому API Yandex Object Storage.
class _SigV4 {
  static const _service = 's3';

  static Map<String, String> signedHeaders({
    required String method,
    required String canonicalPath,
    required List<int> body,
  }) {
    final now = DateTime.now().toUtc();
    final amzDate = _amzDate(now);
    final dateStamp = _dateStamp(now);
    final payloadHash = sha256.convert(body).toString();

    final headers = <String, String>{
      'host': _YandexConfig.endpointHost,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
    };

    final sortedNames = headers.keys.toList()..sort();
    final canonicalHeaders = sortedNames.map((k) => '$k:${headers[k]!.trim()}\n').join();
    final signedHeaderNames = sortedNames.join(';');

    final canonicalRequest = [
      method,
      canonicalPath,
      '',
      canonicalHeaders,
      signedHeaderNames,
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/${_YandexConfig.region}/$_service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final signingKey = _deriveSigningKey(dateStamp);
    final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    final authorization = 'AWS4-HMAC-SHA256 '
        'Credential=${_YandexConfig.accessKeyId}/$credentialScope, '
        'SignedHeaders=$signedHeaderNames, '
        'Signature=$signature';

    return {...headers, 'Authorization': authorization};
  }

  static List<int> _deriveSigningKey(String dateStamp) {
    List<int> hmac(List<int> key, String data) => Hmac(sha256, key).convert(utf8.encode(data)).bytes;
    final kDate = hmac(utf8.encode('AWS4${_YandexConfig.secretAccessKey}'), dateStamp);
    final kRegion = hmac(kDate, _YandexConfig.region);
    final kService = hmac(kRegion, _service);
    return hmac(kService, 'aws4_request');
  }

  static String _amzDate(DateTime utc) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static String _dateStamp(DateTime utc) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}';
  }
}

class _ConflictException implements Exception {}

/// Аккаунт-контроллер, который берёт логин/пароль/почту не с локального
/// диска, а с сервера — тем же способом, что и мобильная версия
/// (YandexStorageApiService): один JSON-документ `db/users.json` в бакете
/// Yandex Object Storage, читаемый и обновляемый через S3 API с
/// условными запросами (If-Match/If-None-Match), чтобы два устройства,
/// правящие список аккаунтов одновременно, не затирали правки друг друга.
///
/// Локально (SharedPreferences) кэшируется только текущая сессия
/// (email + токен + имя), чтобы не спрашивать пароль при каждом запуске
/// приложения — сами пароли и список аккаунтов больше не хранятся на ПК.
class AuthController extends ChangeNotifier {
  static const _usersKey = 'db/users.json';
  static const _sessionKey = 'auth_session';
  static const _maxRetries = 8;

  final _rng = Random.secure();
  SharedPreferences? _prefs;

  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;
  String? _sessionToken;
  bool _isReady = false;

  /// true, пока идёт загрузка сохранённой сессии при старте.
  bool get isReady => _isReady;

  /// Серверный id аккаунта (row['id'] в db/users.json) — используется
  /// бэкендом для привязки лайков/плейлистов к конкретному пользователю
  /// (см. AudioBackend.fetchFavoriteTrackIds/setFavorite).
  String? get currentUserId => _currentUserId;

  /// Email текущего пользователя, если есть активная сессия.
  String? get currentUserEmail => _currentUserEmail;

  /// Имя аккаунта текущего пользователя.
  String? get currentUserName => _currentUserName;

  bool get isLoggedIn => _currentUserEmail != null;

  /// Восстанавливает сохранённую локально сессию (id/email/имя/токен).
  /// Сами данные аккаунтов (пароли и т.д.) на диске больше не лежат —
  /// они читаются с сервера при следующем логине/регистрации.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final raw = _prefs!.getString(_sessionKey);
    if (raw != null) {
      final session = jsonDecode(raw) as Map<String, dynamic>;
      _currentUserId = session['id'] as String?;
      _currentUserEmail = session['email'] as String?;
      _currentUserName = session['name'] as String?;
      _sessionToken = session['token'] as String?;
    }

    _isReady = true;
    notifyListeners();
  }


  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _randomId() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashPassword(String password) {
    final salt = _randomId();
    final hash = sha256.convert(utf8.encode('$salt:$password')).toString();
    return '$salt:$hash';
  }

  bool _checkPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final actual = sha256.convert(utf8.encode('${parts[0]}:$password')).toString();
    return actual == parts[1];
  }

  // --- Низкоуровневые запросы к Yandex Object Storage ---------------------
  String _objectPath(String key) =>
      '/${_YandexConfig.bucket}/${key.split('/').map(Uri.encodeComponent).join('/')}';

  Uri _uri(String key) => Uri.parse('https://${_YandexConfig.endpointHost}${_objectPath(key)}');

  Future<({List<int> bytes, String? etag})?> _getObject(String key) async {
    final path = _objectPath(key);
    final headers = _SigV4.signedHeaders(method: 'GET', canonicalPath: path, body: const []);
    final res = await http.get(_uri(key), headers: headers);
    if (res.statusCode == 404) return null;
    if (res.statusCode >= 400) {
      throw Exception('Yandex Storage GET failed (${res.statusCode}): ${res.body}');
    }
    return (bytes: res.bodyBytes, etag: res.headers['etag']?.replaceAll('"', ''));
  }

  Future<void> _putObject(
    String key,
    List<int> body, {
    String? ifMatch,
    bool createOnly = false,
  }) async {
    final path = _objectPath(key);
    final headers = _SigV4.signedHeaders(method: 'PUT', canonicalPath: path, body: body);
    headers['content-type'] = 'application/json';
    if (ifMatch != null) headers['if-match'] = ifMatch;
    if (createOnly) headers['if-none-match'] = '*';

    final res = await http.put(_uri(key), headers: headers, body: body);
    if (res.statusCode == 412) throw _ConflictException();
    if (res.statusCode >= 400) {
      throw Exception('Yandex Storage PUT failed (${res.statusCode}): ${res.body}');
    }
  }

  /// Читает `db/users.json`, даёт вызывающему коду изменить его и
  /// сохраняет обратно, автоматически повторяя попытку, если другое
  /// устройство успело записать файл первым (оптимистичная блокировка).
  ///
  /// Если [mutate] возвращает null, запись на сервер не выполняется —
  /// так login/register не тратят лишний запрос, когда email не найден,
  /// пароль неверный или аккаунт уже существует.
  Future<T?> _withUsers<T>(T? Function(List<dynamic> items) mutate) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final obj = await _getObject(_usersKey);
      final data = obj == null
          ? <String, dynamic>{'items': <dynamic>[]}
          : jsonDecode(utf8.decode(obj.bytes)) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      final result = mutate(items);
      if (result == null) return null;

      final body = utf8.encode(jsonEncode(data));
      try {
        if (obj == null) {
          await _putObject(_usersKey, body, createOnly: true);
        } else {
          await _putObject(_usersKey, body, ifMatch: obj.etag);
        }
        return result;
      } on _ConflictException {
        await Future.delayed(Duration(milliseconds: (50 * (1 << attempt)).clamp(0, 1000)) +
            Duration(milliseconds: _rng.nextInt(50)));
        continue;
      }
    }
    throw Exception('Слишком много одновременных изменений аккаунтов, попробуйте ещё раз');
  }

  // --- Публичный API (не изменился, чтобы не трогать остальные файлы) -----

  /// Регистрирует нового пользователя на сервере (email + пароль + имя)
  /// и сразу выполняет вход.
  Future<AuthResult> register(String email, String password, String accountName) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || password.isEmpty || accountName.trim().isEmpty) {
      return AuthResult.invalidInput;
    }
    if (!_emailRegex.hasMatch(normalized)) {
      return AuthResult.invalidEmail;
    }

    final row = await _withUsers((items) {
      if (items.any((r) => (r as Map)['email'] == normalized)) {
        return null; // уже существует — не пишем на сервер
      }
      final newRow = {
        'id': _randomId(),
        'email': normalized,
        'password_hash': _hashPassword(password),
        'display_name': accountName.trim(),
        'token': _randomId(),
      };
      items.add(newRow);
      return newRow;
    });

    if (row == null) return AuthResult.userAlreadyExists;

    await _setSession(
      id: row['id'] as String,
      email: normalized,
      name: row['display_name'] as String,
      token: row['token'] as String,
    );
    return AuthResult.success;
  }

  /// Проверяет email/пароль на сервере и открывает сессию при совпадении.
  Future<AuthResult> login(String email, String password) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || password.isEmpty) {
      return AuthResult.invalidInput;
    }
    if (!_emailRegex.hasMatch(normalized)) {
      return AuthResult.invalidEmail;
    }

    // Сначала читаем без записи, чтобы дать точную причину отказа
    // (не найден / неверный пароль), не трогая файл на сервере.
    final obj = await _getObject(_usersKey);
    final data = obj == null
        ? <String, dynamic>{'items': <dynamic>[]}
        : jsonDecode(utf8.decode(obj.bytes)) as Map<String, dynamic>;
    final existing = (data['items'] as List<dynamic>).cast<Map<String, dynamic>?>().firstWhere(
          (r) => r?['email'] == normalized,
          orElse: () => null,
        );
    if (existing == null) return AuthResult.userNotFound;
    if (!_checkPassword(password, existing['password_hash'] as String)) {
      return AuthResult.wrongPassword;
    }

    // Пароль верный — обновляем токен сессии на сервере (с ретраем на
    // случай конкурентной записи с другого устройства).
    final row = await _withUsers((items) {
      final match = items.cast<Map<String, dynamic>?>().firstWhere(
            (r) => r?['email'] == normalized,
            orElse: () => null,
          );
      if (match == null) return null;
      match['token'] = _randomId();
      return match;
    });
    if (row == null) return AuthResult.userNotFound;

    await _setSession(
      id: row['id'] as String,
      email: normalized,
      name: row['display_name'] as String,
      token: row['token'] as String,
    );
    return AuthResult.success;
  }

  Future<void> _setSession({
    required String id,
    required String email,
    required String name,
    required String token,
  }) async {
    _currentUserId = id;
    _currentUserEmail = email;
    _currentUserName = name;
    _sessionToken = token;
    await _prefs!.setString(_sessionKey, jsonEncode({'id': id, 'email': email, 'name': name, 'token': token}));
    notifyListeners();
  }

  /// Завершает текущую сессию — приложение снова покажет экран входа.
  Future<void> logout() async {
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserName = null;
    _sessionToken = null;
    await _prefs!.remove(_sessionKey);
    notifyListeners();
  }
}
