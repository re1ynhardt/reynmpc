import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'backend/audio_backend.dart';
import 'backend/mock_audio_backend.dart';
import 'backend/yandex_storage_audio_backend.dart';
import 'backend/yandex_storage_config.dart';
import 'library/music_library.dart';
import 'localization/locale_controller.dart';
import 'player/player_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  // just_audio сам не умеет играть звук на Windows/Linux — эта строка
  // подключает реализацию через media_kit (libmpv), см. pubspec.yaml.
  // Без неё play() на Windows молча ничего не делает: интерфейс думает,
  // что трек играет, а по факту декодировать/выводить звук некому.
  JustAudioMediaKit.ensureInitialized(windows: true, linux: true);

  runApp(SpotifyCloneApp(backend: _createBackend()));
}

/// 👇 Подключение бэкенда.
///
/// По умолчанию используется то же Yandex Object Storage, что и в
/// мобильном приложении (см. lib/backend/yandex_storage_config.dart —
/// там нужно вписать accessKey/secretKey).
///
/// Если ключи ещё не вписаны (остались значения-заглушки), приложение
/// не падает при запуске, а автоматически откатывается на мок с
/// тестовыми данными — чтобы ПК-версию можно было собрать и запустить
/// в любой момент, даже до подключения хранилища.
AudioBackend _createBackend() {
  const placeholder = 'PASTE_';
  final keysFilledIn = !yandexStorageConfig.accessKey.startsWith(placeholder) &&
      !yandexStorageConfig.secretKey.startsWith(placeholder);

  if (keysFilledIn) {
    return YandexStorageAudioBackend(yandexStorageConfig);
  }

  if (kDebugMode) {
    debugPrint(
      'yandexStorageConfig: accessKey/secretKey не заполнены — '
      'используется MockAudioBackend. Впишите ключи в '
      'lib/backend/yandex_storage_config.dart, чтобы подключить реальное '
      'хранилище.',
    );
  }
  return MockAudioBackend();
}

class SpotifyCloneApp extends StatelessWidget {
  final AudioBackend backend;

  const SpotifyCloneApp({super.key, required this.backend});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioBackend>.value(value: backend),
        ChangeNotifierProvider(create: (_) => MusicLibrary(backend)),
        ChangeNotifierProvider(create: (_) => PlayerController(backend)),
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        // Аккаунт (вход/регистрация) — см. AuthGate ниже: пока пользователь
        // не авторизован, показывается AuthScreen вместо HomeScreen.
        ChangeNotifierProvider(create: (_) => AuthController()..init()),
      ],
      // Builder — чтобы context внутри уже видел провайдеры выше (в том
      // числе ThemeController и AuthController) при выборе themeMode для
      // MaterialApp.
      child: Builder(
        builder: (context) {
          final themeController = context.watch<ThemeController>();
          return MaterialApp(
            title: 'Fluttify',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.mode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Точка входа в приложение с точки зрения авторизации.
///
/// Пока сохранённая сессия ещё загружается — показывает индикатор.
/// Дальше — либо AuthScreen (вход/регистрация), либо HomeScreen, если
/// пользователь уже авторизован (в том числе автоматически, если сессия
/// была сохранена с прошлого запуска).
///
/// Заодно следит за сменой пользователя (вход/выход) и подгружает его
/// лайкнутые треки из MusicLibrary — см. [MusicLibrary.loadFavoritesForUser].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Чтобы не дёргать loadFavoritesForUser на каждый notifyListeners(),
  // а только когда реально сменился пользователь (вход/выход/другой
  // аккаунт).
  Object? _favoritesLoadedFor = false; // false — ещё ни разу не грузили

  void _syncFavorites(AuthController auth) {
    if (!auth.isReady) return;
    final userId = auth.currentUserId;
    if (_favoritesLoadedFor == userId) return;
    _favoritesLoadedFor = userId;
    // postFrameCallback — чтобы не вызывать notifyListeners() у
    // MusicLibrary прямо во время build() этого виджета.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MusicLibrary>().loadFavoritesForUser(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    _syncFavorites(auth);

    if (!auth.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.isLoggedIn ? const HomeScreen() : const AuthScreen();
  }
}
