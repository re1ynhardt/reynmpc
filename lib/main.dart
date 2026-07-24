import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'backend/audio_backend.dart';
import 'backend/mock_audio_backend.dart';
// import 'backend/yandex_storage_audio_backend.dart';
// import 'backend/yandex_storage_config.dart';
import 'library/music_library.dart';
import 'localization/locale_controller.dart';
import 'player/player_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  // 👇 Подключение бэкенда — ОДНА строка.
  //
  // Сейчас используется мок с тестовыми данными:
  runApp(SpotifyCloneApp(backend: MockAudioBackend()));

  // Когда заполните ключи в lib/backend/yandex_storage_config.dart —
  // просто раскомментируйте импорты выше и замените строку на:
  //
  //   runApp(SpotifyCloneApp(backend: YandexStorageAudioBackend(yandexStorageConfig)));
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
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.isLoggedIn ? const HomeScreen() : const AuthScreen();
  }
}
