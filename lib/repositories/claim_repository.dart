import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/services/xml_service.dart';
import 'package:project_xmedit/services/logger.dart';
import 'package:project_xmedit/utils/attachment_helper.dart';
import 'package:universal_io/io.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class ClaimRepository {
  Future<FilePickResult?> pickXmlFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );

      if (result != null) {
        String xmlString;
        String? filePath;

        if (kIsWeb) {
          final bytes = result.files.single.bytes!;
          xmlString = utf8.decode(bytes);
          filePath = result.files.single.name;
        } else if (result.files.single.path != null) {
          filePath = result.files.single.path!;
          final file = File(filePath);
          xmlString = await file.readAsString();
        } else {
          return null;
        }

        return FilePickResult(xmlString: xmlString, filePath: filePath);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error picking XML file', e, stackTrace);
      rethrow;
    }
    return null;
  }

  Future<ClaimData> parseXml(String xmlString) async {
    return await compute(parseXmlInBackground, xmlString);
  }

  Future<String> generateXml(ClaimData claimData) async {
    return await compute(generateXmlString, claimData);
  }

  Future<void> saveFile({
    required String xmlString,
    required String fileName,
    bool saveAs = false,
  }) async {
    if (kIsWeb) {
      final bytes = utf8.encode(xmlString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = fileName;
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } else {
      String? outputFile;
      if (saveAs) {
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xml'],
        );
      } else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          throw Exception("Could not find Downloads directory.");
        }
        outputFile = p.join(downloadsDir.path, fileName);
      }

      if (outputFile != null) {
        await File(outputFile).writeAsString(xmlString);
      } else {
        throw UserCancelledException();
      }
    }
  }

  Future<String?> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      if (kIsWeb) {
        final bytes = result.files.single.bytes!;
        return AttachmentHelper.encodeFromBytes(bytes);
      } else if (result.files.single.path != null) {
        return await AttachmentHelper.encodeFromFile(result.files.single.path!);
      }
    }
    return null;
  }
}

class FilePickResult {
  final String xmlString;
  final String? filePath;

  FilePickResult({required this.xmlString, required this.filePath});
}

class UserCancelledException implements Exception {}
