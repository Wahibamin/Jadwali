import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's persisted appearance settings.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._preferences) {
    _isDarkMode = _preferences.getBool(_darkModeKey) ?? false;
    _primaryColorValue =
        _preferences.getInt(_primaryColorKey) ?? Colors.indigo.toARGB32();
    notifyListeners();
  }

  static const String _darkModeKey = 'is_dark_mode';
  static const String _primaryColorKey = 'primary_color_value';

  final SharedPreferences _preferences;

  bool _isDarkMode = false;
  int _primaryColorValue = Colors.indigo.toARGB32();

  bool get isDarkMode => _isDarkMode;
  int get primaryColorValue => _primaryColorValue;

  /// Persists and applies the selected brightness mode.
  Future<void> toggleDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) {
      return;
    }

    await _preferences.setBool(_darkModeKey, isDark);
    _isDarkMode = isDark;
    notifyListeners();
  }

  /// Persists and applies a new Material seed color.
  Future<void> changePrimaryColor(Color color) async {
    final colorValue = color.toARGB32();
    if (_primaryColorValue == colorValue) {
      return;
    }

    await _preferences.setInt(_primaryColorKey, colorValue);
    _primaryColorValue = colorValue;
    notifyListeners();
  }
}
