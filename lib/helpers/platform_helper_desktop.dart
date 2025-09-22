// Re-export the real DropTarget widget from the desktop_drop package
export 'package:desktop_drop/desktop_drop.dart' show DropTarget;

// Stub (placeholder) implementation for Desktop
class WebDownloadHelper {
  static void downloadFile(String content, String fileName) {
    throw UnsupportedError('downloadFile is only available on the web.');
  }

  static void openFile(String base64Content, String fileName) {
    throw UnsupportedError('openFile is only available on the web.');
  }
}