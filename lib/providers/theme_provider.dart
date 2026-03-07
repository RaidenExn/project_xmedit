import 'package:flutter/material.dart';
import 'package:project_xmedit/services/preferences_service.dart';

class ThemeNotifier extends ChangeNotifier {
  static const Color defaultSeedColor = Color(0xFF2B5FA7);

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = defaultSeedColor;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  final List<Color> _availableColors = const [
    Color(0xFF2B5FA7), // Sapphire
    Color(0xFF1F7A5C), // Emerald
    Color(0xFF8B3D4F), // Bordeaux
    Color(0xFF5A46A6), // Indigo
    Color(0xFFA06321), // Amber Bronze
    Color(0xFF0F7B7B), // Ocean Teal
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

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void changeSeedColor(Color color) {
    _seedColor = color;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final modeStr = await PreferencesService.getThemeMode();
    switch (modeStr) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    final int? colorValue = await PreferencesService.getSeedColor();
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    String modeStr;
    switch (_themeMode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      default:
        modeStr = 'system';
    }
    await PreferencesService.setThemeMode(modeStr);
    await PreferencesService.setSeedColor(_seedColor.toARGB32());
  }
}
