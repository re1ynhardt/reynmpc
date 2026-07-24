import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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

/// Простой локальный аккаунт-контроллер.
///
/// В приложении нет собственного бэкенда для аккаунтов (аудио-бэкенд —
/// отдельная вещь, см. lib/backend), поэтому регистрация/вход хранятся
/// локально через SharedPreferences:
///  - `auth_users`      — JSON-словарь {email: sha256(password+salt)}
///  - `auth_salts`      — JSON-словарь {email: salt}
///  - `auth_names`      — JSON-словарь {email: имя аккаунта}
///  - `auth_current_user` — email активной сессии (для автовхода при
///    следующем запуске приложения)
///
/// Пароли никогда не хранятся в открытом виде — только соль + хеш.
class AuthController extends ChangeNotifier {
  static const _usersKey = 'auth_users';
  static const _saltsKey = 'auth_salts';
  static const _namesKey = 'auth_names';
  static const _sessionKey = 'auth_current_user';

  SharedPreferences? _prefs;
  Map<String, String> _users = {}; // email -> passwordHash
  Map<String, String> _salts = {}; // email -> salt
  Map<String, String> _names = {}; // email -> имя аккаунта

  String? _currentUserEmail;
  bool _isReady = false;

  /// true, пока идёт загрузка сохранённой сессии/аккаунтов при старте.
  bool get isReady => _isReady;

  /// Email текущего пользователя, если есть активная сессия.
  String? get currentUserEmail => _currentUserEmail;

  /// Имя аккаунта текущего пользователя (то, что он ввёл при регистрации).
  String? get currentUserName =>
      _currentUserEmail == null ? null : _names[_currentUserEmail];

  bool get isLoggedIn => _currentUserEmail != null;

  /// Загружает сохранённые аккаунты и восстанавливает сессию, если она
  /// была активна в прошлый запуск приложения.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final usersRaw = _prefs!.getString(_usersKey);
    final saltsRaw = _prefs!.getString(_saltsKey);
    final namesRaw = _prefs!.getString(_namesKey);
    if (usersRaw != null) {
      _users = Map<String, String>.from(jsonDecode(usersRaw) as Map);
    }
    if (saltsRaw != null) {
      _salts = Map<String, String>.from(jsonDecode(saltsRaw) as Map);
    }
    if (namesRaw != null) {
      _names = Map<String, String>.from(jsonDecode(namesRaw) as Map);
    }

    _currentUserEmail = _prefs!.getString(_sessionKey);

    _isReady = true;
    notifyListeners();
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  String _generateSalt(String email) {
    // Соль детерминированная, но уникальная на пользователя — этого
    // достаточно, чтобы не хранить пароли в открытом виде без введения
    // зависимости от генератора случайных чисел с проверкой платформы.
    return sha256.convert(utf8.encode('${DateTime.now().microsecondsSinceEpoch}:$email')).toString().substring(0, 16);
  }

  Future<void> _persistAccounts() async {
    await _prefs!.setString(_usersKey, jsonEncode(_users));
    await _prefs!.setString(_saltsKey, jsonEncode(_salts));
    await _prefs!.setString(_namesKey, jsonEncode(_names));
  }

  /// Регистрирует нового пользователя (email + пароль + имя аккаунта)
  /// и сразу выполняет вход.
  Future<AuthResult> register(String email, String password, String accountName) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || password.isEmpty || accountName.trim().isEmpty) {
      return AuthResult.invalidInput;
    }
    if (!_emailRegex.hasMatch(normalized)) {
      return AuthResult.invalidEmail;
    }
    if (_users.containsKey(normalized)) {
      return AuthResult.userAlreadyExists;
    }

    final salt = _generateSalt(normalized);
    _salts[normalized] = salt;
    _users[normalized] = _hash(password, salt);
    _names[normalized] = accountName.trim();
    await _persistAccounts();

    await _setSession(normalized);
    return AuthResult.success;
  }

  /// Проверяет email/пароль и открывает сессию при совпадении.
  Future<AuthResult> login(String email, String password) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || password.isEmpty) {
      return AuthResult.invalidInput;
    }
    if (!_emailRegex.hasMatch(normalized)) {
      return AuthResult.invalidEmail;
    }
    if (!_users.containsKey(normalized)) {
      return AuthResult.userNotFound;
    }

    final salt = _salts[normalized] ?? '';
    final expectedHash = _users[normalized];
    if (_hash(password, salt) != expectedHash) {
      return AuthResult.wrongPassword;
    }

    await _setSession(normalized);
    return AuthResult.success;
  }

  Future<void> _setSession(String email) async {
    _currentUserEmail = email;
    await _prefs!.setString(_sessionKey, email);
    notifyListeners();
  }

  /// Завершает текущую сессию — приложение снова покажет экран входа.
  Future<void> logout() async {
    _currentUserEmail = null;
    await _prefs!.remove(_sessionKey);
    notifyListeners();
  }
}
