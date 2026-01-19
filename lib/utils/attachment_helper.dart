import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class AttachmentHelper {
  static Future<String> encodeFromFile(String filePath) async {
    // This method handles file paths (Desktop)
    if (kIsWeb) {
      throw UnsupportedError(
          'encodeFromFile is not supported on Web. Use encodeFromBytes.');
    }
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at path: $filePath');
    }
    final Uint8List fileBytes = await file.readAsBytes();
    return base64Encode(fileBytes);
  }

  static String encodeFromBytes(Uint8List bytes) {
    return base64Encode(bytes);
  }

  static Future<File?> decodeToTempFile(String base64Content) async {
    if (kIsWeb) return null;
    final Uint8List bytes = base64Decode(base64Content);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/attachment_preview.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> viewDecodedFile(
      String base64Content, BuildContext context) async {
    try {
      if (kIsWeb) {
        final bytes = base64Decode(base64Content);
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)..target = '_blank';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        final file = await decodeToTempFile(base64Content);
        if (file != null) {
          if (!await launchUrl(file.uri,
              mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch ${file.uri}');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }
}
