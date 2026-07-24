import 'app_language.dart';

/// Простая типобезопасная локализация: набор строк интерфейса на двух
/// языках. Не завязана на flutter_localizations/intl — достаточно для
/// небольшого набора текстов и не требует генерации кода.
abstract class AppStrings {
  String get navHome;
  String get navSearch;
  String get navLibrary;
  String get settings;

  String get playlistsHeader;
  String get playlistLabel;
  String get searchHint;
  String get columnTitle;
  String get columnAlbum;
  String get searchPrompt;
  String get libraryEmpty;

  String get settingsTitle;
  String get languageLabel;
  String get languageRu;
  String get languageEn;
  String get close;

  static AppStrings of(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ru:
        return const _StringsRu();
      case AppLanguage.en:
        return const _StringsEn();
    }
  }
}

class _StringsRu implements AppStrings {
  const _StringsRu();

  @override
  String get navHome => 'Главная';
  @override
  String get navSearch => 'Поиск';
  @override
  String get navLibrary => 'Моя медиатека';
  @override
  String get settings => 'Настройки';

  @override
  String get playlistsHeader => 'ПЛЕЙЛИСТЫ';
  @override
  String get playlistLabel => 'ПЛЕЙЛИСТ';
  @override
  String get searchHint => 'Что хотите послушать?';
  @override
  String get columnTitle => 'НАЗВАНИЕ';
  @override
  String get columnAlbum => 'АЛЬБОМ';
  @override
  String get searchPrompt => 'Начните вводить название трека или исполнителя';
  @override
  String get libraryEmpty => 'Плейлистов пока нет';

  @override
  String get settingsTitle => 'Настройки';
  @override
  String get languageLabel => 'Язык';
  @override
  String get languageRu => 'Русский';
  @override
  String get languageEn => 'English';
  @override
  String get close => 'Закрыть';
}

class _StringsEn implements AppStrings {
  const _StringsEn();

  @override
  String get navHome => 'Home';
  @override
  String get navSearch => 'Search';
  @override
  String get navLibrary => 'Your Library';
  @override
  String get settings => 'Settings';

  @override
  String get playlistsHeader => 'PLAYLISTS';
  @override
  String get playlistLabel => 'PLAYLIST';
  @override
  String get searchHint => 'What do you want to listen to?';
  @override
  String get columnTitle => 'TITLE';
  @override
  String get columnAlbum => 'ALBUM';
  @override
  String get searchPrompt => 'Start typing a song or artist name';
  @override
  String get libraryEmpty => 'No playlists yet';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get languageLabel => 'Language';
  @override
  String get languageRu => 'Русский';
  @override
  String get languageEn => 'English';
  @override
  String get close => 'Close';
}
