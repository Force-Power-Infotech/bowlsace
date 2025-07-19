import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../utils/local_storage.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final LocalStorage _localStorage = getIt<LocalStorage>();

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    _isDarkMode = await _localStorage.getItem('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _localStorage.setItem('darkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
