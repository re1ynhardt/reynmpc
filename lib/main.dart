import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'backend/audio_backend.dart';
import 'backend/mock_audio_backend.dart';
// import 'backend/yandex_storage_audio_backend.dart';
// import 'backend/yandex_storage_config.dart';
import 'library/music_library.dart';
import 'localization/locale_controller.dart';
import 'player/player_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

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
      ],
      child: MaterialApp(
        title: 'Fluttify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
