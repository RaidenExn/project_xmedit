import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'package:desktop_drop/desktop_drop.dart' as desktop;

// Real implementation for Web
class WebDownloadHelper {
  static void downloadFile(String content, String fileName) {
    final bytes = utf8.encode(content);
    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..setAttribute("download", fileName)
      ..click();
    web.URL.revokeObjectURL(url);
  }

  static void openFile(String base64Content, String fileName) {
    final bytes = base64Decode(base64Content);
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    web.window.open(url, '_blank');
  }
}

// Stub (placeholder) implementation for Web
class DropTarget extends StatelessWidget {
  final Widget child;
  final Function(desktop.DropDoneDetails)? onDragDone;
  final Function(desktop.DropEventDetails)? onDragEntered;
  // FIX: This signature is now corrected to match the real package
  final Function(desktop.DropEventDetails)? onDragExited;

  const DropTarget({
    super.key,
    required this.child,
    this.onDragDone,
    this.onDragEntered,
    this.onDragExited,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}