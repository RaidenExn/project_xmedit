import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.green;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  final List<Color> _availableColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  List<Color> get availableColors => _availableColors;

  ThemeNotifier() {
    _loadPreferences();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _savePreferences();
    notifyListeners();
  }

  void changeSeedColor(Color color) {
    _seedColor = color;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final int? colorValue = _prefs.getInt('themeColor');
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
  }

  Future<void> _savePreferences() async {
    await _prefs.setInt('themeColor', _seedColor.toARGB32());
  }
}
