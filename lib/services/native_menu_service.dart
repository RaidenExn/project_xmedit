import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Service for handling native macOS menu bar actions
class NativeMenuService {
  static const MethodChannel _channel = MethodChannel('com.xmedit.app/menu');

  /// Callbacks for menu actions
  static VoidCallback? onOpen;
  static VoidCallback? onSave;
  static VoidCallback? onSaveAs;
  static VoidCallback? onUndo;
  static VoidCallback? onReset;
  static VoidCallback? onClearAll;
  static VoidCallback? onToggleTheme;

  /// Initialize the method channel handler
  static void initialize() {
    if (!Platform.isMacOS) return;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'menuAction':
          final action = call.arguments as String?;
          _handleMenuAction(action);
          break;
      }
    });
  }

  static void _handleMenuAction(String? action) {
    switch (action) {
      case 'open':
        onOpen?.call();
        break;
      case 'save':
        onSave?.call();
        break;
      case 'saveAs':
        onSaveAs?.call();
        break;
      case 'undo':
        onUndo?.call();
        break;
      case 'reset':
        onReset?.call();
        break;
      case 'clearAll':
        onClearAll?.call();
        break;
      case 'toggleTheme':
        onToggleTheme?.call();
        break;
    }
  }

  /// Check if we should use native menu (macOS only)
  static bool get useNativeMenu => Platform.isMacOS;
}
