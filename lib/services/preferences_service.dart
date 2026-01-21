import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing recent files and app preferences
class PreferencesService {
  static const String _recentFilesKey = 'recent_files';
  static const String _maxRecentFilesKey = 'max_recent_files';
  static const String _autoSaveKey = 'auto_save';
  static const String _windowSizeKey = 'window_size';

  static const int defaultMaxRecentFiles = 10;

  /// Add file to recent files list
  static Future<void> addRecentFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final recentFiles = await getRecentFiles();

    // Remove if already exists
    recentFiles.remove(filePath);

    // Add to beginning
    recentFiles.insert(0, filePath);

    // Limit size
    final maxFiles = prefs.getInt(_maxRecentFilesKey) ?? defaultMaxRecentFiles;
    if (recentFiles.length > maxFiles) {
      recentFiles.removeRange(maxFiles, recentFiles.length);
    }

    await prefs.setStringList(_recentFilesKey, recentFiles);
  }

  /// Get list of recent files
  static Future<List<String>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentFilesKey) ?? [];
  }

  /// Clear recent files
  static Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentFilesKey);
  }

  /// Remove specific file from recents
  static Future<void> removeRecentFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final recentFiles = await getRecentFiles();
    recentFiles.remove(filePath);
    await prefs.setStringList(_recentFilesKey, recentFiles);
  }

  /// Get/Set auto-save preference
  static Future<bool> getAutoSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSaveKey) ?? false;
  }

  static Future<void> setAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, value);
  }

  /// Save window size
  static Future<void> saveWindowSize(double width, double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _windowSizeKey, jsonEncode({'width': width, 'height': height}));
  }

  /// Get saved window size
  static Future<Map<String, double>?> getWindowSize() async {
    final prefs = await SharedPreferences.getInstance();
    final sizeStr = prefs.getString(_windowSizeKey);
    if (sizeStr == null) return null;

    try {
      final Map<String, dynamic> json = jsonDecode(sizeStr);
      return {
        'width': (json['width'] as num).toDouble(),
        'height': (json['height'] as num).toDouble(),
      };
    } catch (e) {
      return null;
    }
  }

  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';

  /// Get saved theme mode
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  /// Save theme mode
  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  /// Get saved seed color value (int)
  static Future<int?> getSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_seedColorKey);
  }

  /// Save seed color value (int)
  static Future<void> setSeedColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, colorValue);
  }
}
