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
  String get libraryLabel;
  String get likedLibraryName;
  String get likedLibraryDescription;
  String get searchHint;
  String get columnTitle;
  String get columnAlbum;
  String get searchPrompt;
  String get libraryEmpty;

  String get settingsTitle;
  String get languageLabel;
  String get languageRu;
  String get languageEn;
  String get themeLabel;
  String get themeDark;
  String get themeLight;
  String get close;

  String get authWelcomeTitle;
  String get authLoginTab;
  String get authRegisterTab;
  String get authEmailField;
  String get authNameField;
  String get authPasswordField;
  String get authLoginButton;
  String get authRegisterButton;
  String get authLogout;
  String get authErrorInvalidInput;
  String get authErrorInvalidEmail;
  String get authErrorUserNotFound;
  String get authErrorWrongPassword;
  String get authErrorUserExists;
  String get authLoggedInAs;

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
  String get libraryLabel => 'БИБЛИОТЕКА';
  @override
  String get likedLibraryName => 'Мои лайкнутые';
  @override
  String get likedLibraryDescription => 'Треки, которые вам понравились';
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
  String get themeLabel => 'Тема';
  @override
  String get themeDark => 'Тёмная';
  @override
  String get themeLight => 'Светлая';
  @override
  String get close => 'Закрыть';

  @override
  String get authWelcomeTitle => 'Добро пожаловать в ReynM';
  @override
  String get authLoginTab => 'Вход';
  @override
  String get authRegisterTab => 'Регистрация';
  @override
  String get authEmailField => 'Почта';
  @override
  String get authNameField => 'Имя аккаунта';
  @override
  String get authPasswordField => 'Пароль';
  @override
  String get authLoginButton => 'Войти';
  @override
  String get authRegisterButton => 'Зарегистрироваться';
  @override
  String get authLogout => 'Выйти из аккаунта';
  @override
  String get authErrorInvalidInput => 'Заполните все поля';
  @override
  String get authErrorInvalidEmail => 'Введите корректную почту';
  @override
  String get authErrorUserNotFound => 'Аккаунт с такой почтой не найден';
  @override
  String get authErrorWrongPassword => 'Неверный пароль';
  @override
  String get authErrorUserExists => 'Аккаунт с такой почтой уже есть';
  @override
  String get authLoggedInAs => 'Вы вошли как';
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
  String get libraryLabel => 'LIBRARY';
  @override
  String get likedLibraryName => 'Liked Songs';
  @override
  String get likedLibraryDescription => 'Songs you\'ve liked';
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
  String get themeLabel => 'Theme';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeLight => 'Light';
  @override
  String get close => 'Close';

  @override
  String get authWelcomeTitle => 'Welcome to ReynM';
  @override
  String get authLoginTab => 'Log in';
  @override
  String get authRegisterTab => 'Sign up';
  @override
  String get authEmailField => 'Email';
  @override
  String get authNameField => 'Account name';
  @override
  String get authPasswordField => 'Password';
  @override
  String get authLoginButton => 'Log in';
  @override
  String get authRegisterButton => 'Create account';
  @override
  String get authLogout => 'Log out';
  @override
  String get authErrorInvalidInput => 'Fill in all fields';
  @override
  String get authErrorInvalidEmail => 'Enter a valid email address';
  @override
  String get authErrorUserNotFound => 'No account with this email';
  @override
  String get authErrorWrongPassword => 'Incorrect password';
  @override
  String get authErrorUserExists => 'An account with this email already exists';
  @override
  String get authLoggedInAs => 'Logged in as';
}
