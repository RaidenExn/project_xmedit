import 'package:universal_io/io.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/models/bulk_claim_models.dart';
import 'package:project_xmedit/services/xml_service.dart';
import 'package:project_xmedit/services/logger.dart';
import 'package:project_xmedit/services/preferences_service.dart';

/// Provider for managing bulk XML claim data with undo/reset capabilities
class BulkClaimDataNotifier extends ChangeNotifier {
  BulkClaimData? _bulkData;
  BulkClaimData? _originalSnapshot;
  final List<BulkClaimData> _undoStack = [];
  List<BulkClaimData> get undoStack => _undoStack;
  final Set<int> _selectedClaimIndices = {}; // Changed from single int to Set
  int _lastSelectedClaimIndex =
      0; // Keep track of last selected for detail view if needed, or focused item
  bool _isLoading = false;
  String? _filePath;
  String _searchQuery = '';
  void Function(String message, bool isError)? onMessage;
  void Function(String xmlString, String? filePath)? onSingleXmlDetected;

  // Maximum undo history to prevent memory issues
  static const int maxUndoStackSize = 10;

  // Getters
  BulkClaimData? get bulkData => _bulkData;
  Set<int> get selectedClaimIndices => _selectedClaimIndices;
  int get selectedClaimIndex =>
      _lastSelectedClaimIndex; // For backward compatibility / detail view focus
  bool get isLoading => _isLoading;
  String? get filePath => _filePath;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canReset => _originalSnapshot != null;

  int get totalClaims => _bulkData?.totalClaims ?? 0;

  String get dispositionFlag => _bulkData?.dispositionFlag ?? 'PRODUCTION';

  void setDispositionFlag(String value) {
    if (_bulkData == null) return;
    if ((_bulkData!.dispositionFlag ?? 'PRODUCTION') == value) return;

    _bulkData!.dispositionFlag = value;
    // Update all claims
    for (var claim in _bulkData!.claims) {
      claim.dispositionFlag = value;
    }

    _bulkData!.rawXml = null; // Invalidate cache
    notifyListeners();
  }

  List<ClaimListItem> get claimListItems {
    final allItems = _bulkData?.getClaimListItems() ?? [];
    if (_searchQuery.isEmpty) return allItems;

    final query = _searchQuery.toLowerCase();
    return allItems.where((item) {
      return item.claimId.toLowerCase().contains(query) ||
          item.patientInfo.toLowerCase().contains(query) ||
          item.gross.contains(query) ||
          item.net.contains(query);
    }).toList();
  }

  String get searchQuery => _searchQuery;

  /// Get currently selected claim data (returns the last selected one for detail view)
  ClaimData? get selectedClaim {
    if (_bulkData == null ||
        _lastSelectedClaimIndex < 0 ||
        _lastSelectedClaimIndex >= _bulkData!.claims.length) {
      return null;
    }
    return _bulkData!.claims[_lastSelectedClaimIndex];
  }

  /// Get estimated file size
  String getEstimatedFileSize() {
    return _bulkData?.getEstimatedFileSize() ?? '0 B';
  }

  /// Get total gross amount across all claims
  double getTotalGross() {
    if (_bulkData == null) return 0.0;
    return _bulkData!.claims.fold(0.0, (sum, claim) {
      final gross = double.tryParse(claim.gross ?? '0') ?? 0.0;
      return sum + gross;
    });
  }

  /// Get total net amount across all claims
  double getTotalNet() {
    if (_bulkData == null) return 0.0;
    return _bulkData!.claims.fold(0.0, (sum, claim) {
      final net = double.tryParse(claim.net ?? '0') ?? 0.0;
      return sum + net;
    });
  }

  /// Get count of filtered claims (for search results)
  int get filteredClaimCount => claimListItems.length;

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// Load bulk XML file from file picker
  Future<void> loadBulkXmlFile() async {
    bool loadingStarted = false;
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );

      if (result != null) {
        _setLoading(true);
        loadingStarted = true;

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
          onMessage?.call('Error: File path is null', true);
          return;
        }

        // Check if it's bulk XML
        if (!detectBulkXml(xmlString)) {
          if (onSingleXmlDetected != null) {
            onSingleXmlDetected!(xmlString, filePath);
          } else {
            onMessage?.call(
                'This XML contains only a single claim. Please use the regular editor.',
                true);
          }
          return;
        }

        // Parse bulk XML in background isolate
        final bulkData = await compute(parseBulkXmlInBackground, xmlString);

        _bulkData = bulkData;
        _bulkData!.filePath = filePath;
        _filePath = filePath;

        // Store original snapshot for reset
        _originalSnapshot = _bulkData!.clone();

        // Clear undo stack
        _undoStack.clear();

        // Reset selection
        _selectedClaimIndices.clear();
        _lastSelectedClaimIndex = 0;

        onMessage?.call(
            'Bulk XML loaded successfully! ${_bulkData!.totalClaims} claims found.',
            false);
      } else {
        onMessage?.call('File selection cancelled.', false);
      }
    } on XmlParsingException catch (e) {
      onMessage?.call(e.message, true);
    } catch (e) {
      onMessage?.call('An unexpected error occurred: $e', true);
    } finally {
      if (loadingStarted) {
        _setLoading(false);
      }
    }
  }

  /// Load bulk XML from string (used when XML is already read)
  Future<void> loadFromXmlString(String xmlString, String? filePath) async {
    try {
      _setLoading(true);

      // Check if it's bulk XML
      if (!detectBulkXml(xmlString)) {
        if (onSingleXmlDetected != null) {
          onSingleXmlDetected!(xmlString, filePath);
        } else {
          onMessage?.call(
              'This XML contains only a single claim. Please use the regular editor.',
              true);
        }
        return;
      }

      // Parse bulk XML in background isolate
      final bulkData = await compute(parseBulkXmlInBackground, xmlString);

      _bulkData = bulkData;
      _bulkData!.filePath = filePath;
      _filePath = filePath;

      // Store original snapshot for reset
      _originalSnapshot = _bulkData!.clone();

      // Clear undo stack
      _undoStack.clear();

      // Reset selection
      _selectedClaimIndices.clear();
      _lastSelectedClaimIndex = 0;

      onMessage?.call(
          'Bulk XML loaded successfully! ${_bulkData!.totalClaims} claims found.',
          false);

      AppLogger.logBulkOperation('Loaded bulk XML', _bulkData!.totalClaims);
      if (filePath != null) {
        await PreferencesService.addRecentFile(filePath);
      }
    } on XmlParsingException catch (e) {
      onMessage?.call(e.message, true);
    } catch (e) {
      onMessage?.call('An unexpected error occurred: $e', true);
    } finally {
      _setLoading(false);
    }
  }

  /// Update search query and filter claims
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search filter
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Select a claim by index (single select mode)
  void selectClaim(int index) {
    if (_bulkData == null || index < 0 || index >= _bulkData!.claims.length) {
      return;
    }
    _selectedClaimIndices.clear();
    _selectedClaimIndices.add(index);
    _lastSelectedClaimIndex = index;
    notifyListeners();
  }

  /// Focus a claim without selecting via checkbox (for viewing details)
  void focusClaim(int index) {
    if (_bulkData == null || index < 0 || index >= _bulkData!.claims.length) {
      return;
    }
    _lastSelectedClaimIndex = index;
    notifyListeners();
  }

  /// Toggle selection of a claim (multi-select mode)
  void toggleClaimSelection(int index) {
    if (_bulkData == null || index < 0 || index >= _bulkData!.claims.length) {
      return;
    }
    if (_selectedClaimIndices.contains(index)) {
      _selectedClaimIndices.remove(index);
      // If we deselected the "last selected", pick another one or 0
      if (_lastSelectedClaimIndex == index) {
        if (_selectedClaimIndices.isNotEmpty) {
          _lastSelectedClaimIndex = _selectedClaimIndices.last;
        } else {
          _lastSelectedClaimIndex = 0; // Fallback
        }
      }
    } else {
      _selectedClaimIndices.add(index);
      _lastSelectedClaimIndex = index;
    }
    notifyListeners();
  }

  void selectAll() {
    if (_bulkData == null) return;
    _selectedClaimIndices.clear();
    for (int i = 0; i < _bulkData!.claims.length; i++) {
      _selectedClaimIndices.add(i);
    }
    notifyListeners();
  }

  void deselectAll() {
    _selectedClaimIndices.clear();
    notifyListeners();
  }

  /// Delete selected claims
  Future<void> deleteSelectedClaims() async {
    if (_bulkData == null || _selectedClaimIndices.isEmpty) {
      return;
    }

    _pushUndoSnapshot();

    final indicesToRemove = _selectedClaimIndices.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order
    final count = indicesToRemove.length;

    for (final index in indicesToRemove) {
      if (index < _bulkData!.claims.length) {
        _bulkData!.claims.removeAt(index);
      }
    }

    _bulkData!.rawXml = null; // Invalidate cache
    _selectedClaimIndices.clear();
    _lastSelectedClaimIndex = 0;

    // Auto-select first if available - DISABLED
    // if (_bulkData!.claims.isNotEmpty) {
    //   _selectedClaimIndices.add(0);
    // }

    notifyListeners();
    onMessage?.call('$count claim(s) deleted.', false);
  }

  /// Delete a single claim (legacy/convenience)
  Future<void> deleteClaim(int index) async {
    if (_bulkData == null || index < 0 || index >= _bulkData!.claims.length) {
      return;
    }

    // Create undo snapshot before deletion
    _pushUndoSnapshot();

    final deletedClaimId = _bulkData!.claims[index].claimId ?? 'UNKNOWN';
    _bulkData!.claims.removeAt(index);
    _bulkData!.rawXml = null; // Invalidate cache

    // Adjust selected index if necessary
    _selectedClaimIndices.remove(index);
    // Re-adjust indices in set logic is complex since everything shifted.
    // Easier to just clear selection or try to keep logical selection.
    // For simplicity, clear and select 0 or similar.
    _selectedClaimIndices.clear();

    _lastSelectedClaimIndex = 0;
    if (_bulkData!.claims.isNotEmpty) {
      // Try to select the same index or one before
      int newIndex = index;
      if (newIndex >= _bulkData!.claims.length) {
        newIndex = _bulkData!.claims.length - 1;
      }
      _selectedClaimIndices.add(newIndex);
      _lastSelectedClaimIndex = newIndex;
    }

    notifyListeners();
    onMessage?.call('Claim $deletedClaimId deleted.', false);
  }

  /// Update a specific claim
  void updateClaim(int index, ClaimData updatedClaim) {
    if (_bulkData == null || index < 0 || index >= _bulkData!.claims.length) {
      return;
    }

    _bulkData!.claims[index] = updatedClaim;
    _bulkData!.rawXml = null; // Invalidate cache
    notifyListeners();
  }

  /// Undo last operation
  void undo() {
    if (_undoStack.isEmpty) {
      onMessage?.call('Nothing to undo.', true);
      return;
    }

    _bulkData = _undoStack.removeLast();

    // Adjust selected index if out of bounds
    _selectedClaimIndices.clear();
    _lastSelectedClaimIndex = 0;
    if (_bulkData!.claims.isNotEmpty) {
      _selectedClaimIndices.add(0);
    }

    notifyListeners();
    onMessage?.call('Undo successful.', false);
  }

  /// Reset to original loaded state
  void reset() {
    if (_originalSnapshot == null) {
      onMessage?.call('No original state to reset to.', true);
      return;
    }

    _bulkData = _originalSnapshot!.clone();
    _undoStack.clear();
    _selectedClaimIndices.clear();
    _lastSelectedClaimIndex = 0;
    // removed auto-selection of first claim

    notifyListeners();
    onMessage?.call('Reset to original state.', false);
  }

  /// Save bulk XML file
  Future<void> saveBulkXmlFile({bool saveAs = false}) async {
    if (_bulkData == null) {
      onMessage?.call('No bulk XML data loaded.', true);
      return;
    }

    _setLoading(true);
    try {
      // Generate XML string in background
      final xmlString = await compute(generateBulkXmlString, _bulkData!);

      String baseFileName = 'bulk_claims_output.xml';

      // Generate filename based on ReceiverID if available
      if (_bulkData != null && _bulkData!.claims.isNotEmpty) {
        final receiverID = _bulkData!.claims.first.receiverID;
        if (receiverID != null && receiverID.isNotEmpty) {
          // Sanitize filename
          final safeId = receiverID.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          final recordCount = _bulkData!.totalClaims;
          final disposition = dispositionFlag;
          final now = DateTime.now();
          final timestamp =
              "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

          baseFileName =
              'bulk_resub_${safeId}_${recordCount}_${disposition}_$timestamp.xml';
        } else if (_filePath != null) {
          baseFileName = p.basename(_filePath!);
        }
      } else if (_filePath != null) {
        baseFileName = p.basename(_filePath!);
      }

      if (kIsWeb) {
        final bytes = utf8.encode(xmlString);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = baseFileName;
        anchor.click();
        html.Url.revokeObjectUrl(url);
        onMessage?.call("Download started for $baseFileName", false);

        // Update original snapshot after save - REMOVED to fix reset behavior
        // _originalSnapshot = _bulkData!.clone();
        _undoStack.clear();
        notifyListeners();
      } else {
        String? outputFile;
        if (saveAs) {
          outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Please select an output file:',
            fileName: baseFileName,
            type: FileType.custom,
            allowedExtensions: ['xml'],
          );
        } else {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir == null) {
            throw Exception("Could not find Downloads directory.");
          }
          outputFile = p.join(downloadsDir.path, baseFileName);
        }

        if (outputFile != null) {
          await File(outputFile).writeAsString(xmlString);
          onMessage?.call(
              "Bulk XML file saved successfully to ${p.basename(outputFile)}",
              false);

          // Update original snapshot after save - REMOVED to fix reset behavior
          _undoStack.clear();
          notifyListeners();
        } else {
          onMessage?.call("Save operation cancelled.", false);
        }
      }
    } catch (e) {
      onMessage?.call("Error saving file: $e", true);
    } finally {
      _setLoading(false);
    }
  }

  /// Split and save bulk XML
  Future<void> splitAndSaveBulkXml() async {
    if (_bulkData == null) {
      onMessage?.call('No data to split.', true);
      return;
    }

    _setLoading(true);
    try {
      const int maxSizeBytes = (2950 * 1024); // 2.95 MB in bytes (approx)

      // We need to generate the header once to know its size
      // We'll use a temporary empty bulk data for that
      final tempHeaderData = BulkClaimData(
        senderID: _bulkData!.senderID,
        receiverID: _bulkData!.receiverID,
        transactionDate: _bulkData!.transactionDate,
        dispositionFlag: _bulkData!.dispositionFlag,
        // RecordCount will be updated per file
      );

      // This is a rough estimation of header/footer overhead
      // <Claim.Submission ...> <Header>...</Header> ... </Claim.Submission>
      // Let's assume ~500 bytes overhead safely.
      // Better yet, generate an empty one and check.
      final emptyXml = generateBulkXmlString(tempHeaderData..claims = []);
      final overhead = utf8.encode(emptyXml).length;

      int currentPart = 1;
      List<ClaimData> currentChunk = [];
      int currentSize = overhead;

      // Helper to save a chunk
      Future<void> saveChunk(List<ClaimData> claims, int partNum) async {
        final chunkData = BulkClaimData(
          senderID: _bulkData!.senderID,
          receiverID: _bulkData!.receiverID,
          transactionDate: _bulkData!.transactionDate,
          dispositionFlag: _bulkData!.dispositionFlag,
          claims: claims,
          recordCount: claims.length.toString(),
        );

        final xmlString = await compute(generateBulkXmlString, chunkData);

        // Filename generation
        String baseFileName = 'split_part$partNum.xml';
        if (_filePath != null) {
          final name = p.basenameWithoutExtension(_filePath!);
          baseFileName = '${name}_part$partNum.xml';
        }

        if (kIsWeb) {
          final bytes = utf8.encode(xmlString);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..target = 'blank'
            ..download = baseFileName;
          anchor.click();
          html.Url.revokeObjectUrl(url);
        } else {
          // For desktop, we might want to ask for a folder, but popping up 10 dialogs is bad.
          // Let's save to Downloads automatically for split operations to be smooth.
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final outputFile = p.join(downloadsDir.path, baseFileName);
            await File(outputFile).writeAsString(xmlString);
          }
        }
      }

      for (final claim in _bulkData!.claims) {
        // We need the size of this claim.
        // If rawXml exists, use it. If not, generate it.
        int claimSize = 0;
        if (claim.rawXml != null) {
          claimSize = claim.rawXml!
              .length; // Approximation (utf8 length might differ slightly but close enough)
        } else {
          // Fallback: generate individual claim XML string
          // This is expensive so we do it only if needed
          // Actually, generateBulkXmlString uses _buildClaimElement.
          // Let's assume distinct claim generation overhead.
          // For logic simplicy, let's treat rawXml length as byte size.
          // If rawXml is null (edited), we must generate it.
          // Ideally we'd have a lightweight generator.
          // Let's just create a dummy XML for size check? No, too slow.
          // Use estimated size or generate.
          final s = generateXmlString(
              claim); // This includes headers/submission tags we don't want.
          // We just want the <Claim> element size.
          // But we can approximate.
          claimSize = s.length;
        }

        // Check if adding this claim exceeds max size
        if (currentSize + claimSize > maxSizeBytes && currentChunk.isNotEmpty) {
          // Save current chunk
          await saveChunk(currentChunk, currentPart);
          currentPart++;
          currentChunk = [];
          currentSize = overhead;
        }

        currentChunk.add(claim);
        currentSize += claimSize;
      }

      // Save remaining
      if (currentChunk.isNotEmpty) {
        await saveChunk(currentChunk, currentPart);
      }

      onMessage?.call('Split complete! Saved $currentPart files.', false);
    } catch (e) {
      onMessage?.call('Error splitting file: $e', true);
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all data
  void clearData() {
    _bulkData = null;
    _originalSnapshot = null;
    _undoStack.clear();
    _selectedClaimIndices.clear();
    _lastSelectedClaimIndex = 0;
    _filePath = null;
    notifyListeners();
    onMessage?.call('Bulk data cleared.', false);
  }

  /// Push current state to undo stack
  void _pushUndoSnapshot() {
    if (_bulkData == null) return;

    // Add current state to undo stack
    _undoStack.add(_bulkData!.clone());

    // Limit stack size
    if (_undoStack.length > maxUndoStackSize) {
      _undoStack.removeAt(0);
    }
  }
}
