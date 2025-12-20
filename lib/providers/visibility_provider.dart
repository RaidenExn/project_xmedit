import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardVisibilityNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;

  final Map<String, bool> _visibilities = {
    'details': true,
    'resubmission & totals': true,
    'activities': true,
    'diagnosis': true,
  };

  Map<String, bool> get visibilities => _visibilities;

  CardVisibilityNotifier() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    for (final key in _visibilities.keys) {
      _visibilities[key] = _prefs.getBool(key) ?? true;
    }
    notifyListeners();
  }

  void toggle(String key) {
    if (_visibilities.containsKey(key)) {
      _visibilities[key] = !_visibilities[key]!;
      _prefs.setBool(key, _visibilities[key]!);
      notifyListeners();
    }
  }
}
