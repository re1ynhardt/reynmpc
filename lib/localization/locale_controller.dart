import 'package:flutter/foundation.dart';

import 'app_language.dart';
import 'app_strings.dart';

/// Держит текущий язык интерфейса и отдаёт готовый набор строк [AppStrings].
/// Подключается в main.dart через ChangeNotifierProvider — так же, как
/// MusicLibrary и PlayerController.
class LocaleController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.ru;

  AppLanguage get language => _language;
  AppStrings get s => AppStrings.of(_language);

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }
}
