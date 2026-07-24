import 'package:flutter/material.dart';

/// Держит текущую тему приложения (тёмная/светлая) и уведомляет слушателей.
/// Подключается в main.dart через ChangeNotifierProvider — так же, как
/// LocaleController хранит текущий язык.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
