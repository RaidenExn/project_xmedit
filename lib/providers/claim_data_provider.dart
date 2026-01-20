import 'package:universal_io/io.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/services/xml_service.dart'
    show
        parseXmlInBackground,
        generateXmlString,
        XmlParsingException,
        detectBulkXml;
import 'package:project_xmedit/utils/attachment_helper.dart';
import 'package:project_xmedit/services/logger.dart';
import 'package:project_xmedit/services/preferences_service.dart';
import 'package:project_xmedit/services/xml_validator.dart';
import 'package:project_xmedit/models/validation_result.dart';

class ClaimDataNotifier extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  ClaimData? _claimData;
  List<DiagnosisData> _originalDiagnoses = [];
  List<ActivityData> _originalActivities = [];
  bool _isLoading = false;
  String? _originalFilePath;
  double _originalPatientShare = 0.0;
  void Function(String message, bool isError)? onMessage;
  void Function(String xmlString, String? filePath)? onBulkXmlDetected;

  bool shouldRenameFile = true;
  String? originalResubmissionType;
  String grossDifference = "";
  String netDifference = "";
  Map<String, String> _cptDescriptions = {};
  bool isDiagnosisEditingEnabled = false;

  bool transferOnDelete = true;
  ValidationResult? _validationResult;

  final TextEditingController grossController = TextEditingController();
  final TextEditingController patientShareController = TextEditingController();
  final TextEditingController netController = TextEditingController();
  final TextEditingController resubmissionCommentController =
      TextEditingController();

  ClaimDataNotifier() {
    _dbHelper.database;
  }

  Map<String, String> get cptDescriptions => _cptDescriptions;
  ClaimData? get claimData => _claimData;
  bool get isLoading => _isLoading;
  List<ActivityData> get originalActivities => _originalActivities;
  ValidationResult? get validationResult => _validationResult;

  Map<String, List<ActivityData>> get groupedActivities {
    if (_claimData == null) return {};
    final map = <String, List<ActivityData>>{};
    for (final activity in _claimData!.activities) {
      (map[activity.type ?? 'unknown'] ??= []).add(activity);
    }
    return map;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearPermanentControllers() {
    grossController.clear();
    patientShareController.clear();
    netController.clear();
    resubmissionCommentController.clear();
  }

  void _updateControllers() {
    // With new architecture, we don't manage activity controllers here anymore.
    // Just clear permanent ones and set their values.

    _clearPermanentControllers();

    grossController.removeListener(_onControllerChanged);
    patientShareController.removeListener(_onControllerChanged);
    netController.removeListener(_onControllerChanged);

    if (_claimData != null) {
      grossController.text = _claimData!.gross ?? '0.00';
      patientShareController.text = _claimData!.patientShare ?? '0.00';
      netController.text = _claimData!.net ?? '0.00';
      resubmissionCommentController.text =
          _claimData!.resubmission?.comment ?? '';
      _originalPatientShare =
          double.tryParse(_claimData!.patientShare ?? '0') ?? 0.0;
      originalResubmissionType = _claimData!.resubmission?.type;

      const resubmissionOptions = [
        "correction",
        "internal complaint",
        "reconciliation"
      ];
      final currentType = _claimData!.resubmission?.type;
      if (currentType == null || !resubmissionOptions.contains(currentType)) {
        (_claimData!.resubmission ??= ResubmissionData()).type =
            'internal complaint';
      }

      // We do NOT initialize activity controllers here.
      // However, we still listen to global controllers.
      for (final c in [
        grossController,
        patientShareController,
        netController,
      ]) {
        c.addListener(_onControllerChanged);
      }
      _checkAllBalances();
    }
  }

  void updateActivityCode(int index, String newCode) {
    if (_claimData == null) return;

    final activity = _claimData!.activities[index];
    final originalActivity = _originalActivities[index];

    activity.code = newCode;

    final isDslCodeModified = activity.code != originalActivity.code;

    if (activity.type == '8' &&
        isDslCodeModified &&
        _claimData!.resubmission?.type != 'correction') {
      (_claimData!.resubmission ??= ResubmissionData()).type = 'correction';
      onMessage?.call(
          'Resubmission type automatically set to "correction" due to DSL code edit.',
          false);
    }
    _validate();
    notifyListeners();
  }

  void updateActivityQuantity(
      int index, String newQuantityText, TextEditingController netController) {
    if (_claimData == null || index >= _claimData!.activities.length) return;

    final originalActivity = _originalActivities[index];
    final originalQty = int.tryParse(originalActivity.quantity ?? '1') ?? 1;
    final originalNet = double.tryParse(originalActivity.net ?? '0.00') ?? 0.0;

    _claimData!.activities[index].quantity = newQuantityText;

    if (originalQty == 0) {
      notifyListeners();
      return;
    }

    final unitPrice = originalNet / originalQty;
    final newQty = int.tryParse(newQuantityText) ?? 0;
    final newNet = newQty * unitPrice;
    final newNetText = newNet.toStringAsFixed(2);

    _claimData!.activities[index].net = newNetText;

    if (netController.text != newNetText) {
      netController.text = newNetText; // This updates the UI via the controller
    } else {
      notifyListeners();
    }
    checkBalances();
    _validate();
  }

  void _onControllerChanged() {
    _checkAllBalances();
    _validate();
    notifyListeners();
  }

  void checkBalances() => _checkAllBalances();

  void onTotalsEdited(String source) {
    final g = double.tryParse(grossController.text) ?? 0.0;
    final ps = double.tryParse(patientShareController.text) ?? 0.0;
    final n = double.tryParse(netController.text) ?? 0.0;
    switch (source) {
      case "gross":
        netController.text = (g - ps).toStringAsFixed(2);
        break;
      case "pshare":
      case "net":
        grossController.text = (n + ps).toStringAsFixed(2);
        break;
    }
    _checkAllBalances();
    notifyListeners();
  }

  void _checkNetBalance() {
    if (_claimData == null) return;
    final totalNetFromActivities = _claimData!.activities
        .where((activity) => !activity.isDeleted)
        .map((activity) => double.tryParse(activity.net ?? '0.00') ?? 0.0)
        .fold(0.0, (prev, val) => prev + val);
    final declaredNet = double.tryParse(netController.text) ?? 0.0;
    final diff = declaredNet - totalNetFromActivities;
    netDifference =
        (diff.abs() > 0.001) ? "(Δ ${diff.toStringAsFixed(2)})" : "";
  }

  void _validate() {
    if (_claimData != null) {
      // Ensure controllers are synced before validation if needed, but
      // XmlValidator reads from ClaimData.
      // We must sync basic fields from controllers to ClaimData for validation
      _claimData!.gross = grossController.text;
      _claimData!.patientShare = patientShareController.text;
      _claimData!.net = netController.text;
      if (_claimData!.resubmission != null) {
        _claimData!.resubmission!.comment = resubmissionCommentController.text;
      }

      _validationResult = XmlValidator.validateClaim(_claimData!);
      // notifyListeners() is usually called by the caller of _validate() or we can call it here if standalone
    } else {
      _validationResult = null;
    }
  }

  void _checkAllBalances() => _checkNetBalance();

  Future<void> loadXmlFile() async {
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

        await loadFromXmlString(xmlString, filePath);
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

  Future<void> loadFromXmlString(String xmlString, String? filePath) async {
    try {
      _setLoading(true);

      // Check if this is bulk XML (multiple claims)
      if (detectBulkXml(xmlString)) {
        // Delegate to bulk editor
        onBulkXmlDetected?.call(xmlString, filePath);
        return;
      }

      final claimData = await compute(parseXmlInBackground, xmlString);

      _claimData = claimData;
      _originalFilePath = filePath;
      // Store original activities for comparison
      _originalDiagnoses =
          _claimData!.diagnoses.map((d) => DiagnosisData.clone(d)).toList();
      _originalActivities =
          _claimData!.activities.map((a) => ActivityData.clone(a)).toList();
      isDiagnosisEditingEnabled = false;
      final activityCodes =
          _claimData!.activities.map((a) => a.code).whereType<String>().toSet();
      _cptDescriptions =
          await _dbHelper.getDescriptionsForCptCodes(activityCodes);
      _updateControllers();
      _validate();

      // Log and add to recent files
      if (filePath != null) {
        AppLogger.logFileOperation('Loaded XML', filePath);
        await PreferencesService.addRecentFile(filePath);
      }

      onMessage?.call('XML file loaded successfully!', false);
    } catch (e) {
      // Re-throw or handle specific exceptions if needed, but for now propagate
      // so caller can handle or we can just log/notify here.
      // Since this is called from loadXmlFile which has try-catch, rethrowing is fine.
      // But we should probably handle it here to be safe for external callers.
      if (e is XmlParsingException) {
        onMessage?.call(e.message, true);
      } else {
        onMessage?.call('An unexpected error occurred: $e', true);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveXmlFile(
      {bool saveAs = false, String? customFileName}) async {
    if (_claimData == null) {
      onMessage?.call('No XML data loaded.', true);
      return;
    }
    _setLoading(true);
    try {
      _claimData!
        ..gross = grossController.text
        ..patientShare = patientShareController.text
        ..net = netController.text;
      if (_claimData!.resubmission != null) {
        _claimData!.resubmission!.comment =
            resubmissionCommentController.text.trim();
      }

      // Perform validation before save
      _validate();
      if (_validationResult != null &&
          _validationResult!.criticalErrors.isNotEmpty) {
        onMessage?.call(
            "Cannot save: ${_validationResult!.criticalErrors.length} critical errors found. Please check validaton panel.",
            true);
        _setLoading(false);
        return;
      }
      // Activities are now updated in real-time, no need to sync from controllers here

      // Double check validation one last time
      if (!XmlValidator.canSave(_claimData!)) {
        onMessage?.call("Validation failed unexpectedly.", true);
        return;
      }

      final xmlString = await compute(generateXmlString, _claimData!);

      final claimId = _claimData!.claimId ?? "UNKNOWN";
      final sanitizedId = claimId.replaceAll(RegExp(r'[^\w-]'), '_');
      final baseFileName = _originalFilePath != null
          ? p.basename(_originalFilePath!)
          : 'output.xml';
      final finalFileName = customFileName ??
          (shouldRenameFile ? 'claim_$sanitizedId.xml' : baseFileName);

      if (kIsWeb) {
        final bytes = utf8.encode(xmlString);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = finalFileName;
        anchor.click();
        html.Url.revokeObjectUrl(url);
        onMessage?.call("Download started for $finalFileName", false);
        _originalActivities =
            _claimData!.activities.map((a) => ActivityData.clone(a)).toList();
        _originalDiagnoses =
            _claimData!.diagnoses.map((d) => DiagnosisData.clone(d)).toList();
        notifyListeners();
      } else {
        String? outputFile;
        if (saveAs) {
          outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Please select an output file:',
            fileName: finalFileName,
            type: FileType.custom,
            allowedExtensions: ['xml'],
          );
        } else {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir == null) {
            throw Exception("Could not find Downloads directory.");
          }
          outputFile = p.join(downloadsDir.path, finalFileName);
        }
        if (outputFile != null) {
          await File(outputFile).writeAsString(xmlString);
          onMessage?.call(
              "XML file saved successfully to ${p.basename(outputFile)}",
              false);
          _originalActivities =
              _claimData!.activities.map((a) => ActivityData.clone(a)).toList();
          _originalDiagnoses =
              _claimData!.diagnoses.map((d) => DiagnosisData.clone(d)).toList();
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

  void clearData() {
    _claimData = null;
    _originalDiagnoses = [];
    _originalActivities = [];
    shouldRenameFile = false;
    grossDifference = "";
    netDifference = "";
    isDiagnosisEditingEnabled = false;
    transferOnDelete = false;
    _cptDescriptions.clear();
    _validationResult = null;
    _updateControllers();
    notifyListeners();
    onMessage?.call('Data has been cleared.', false);
  }

  void toggleActivityDeleted(int index) {
    if (_claimData == null || index >= _claimData!.activities.length) return;

    final activity = _claimData!.activities[index];
    final isUndoing = activity.isDeleted;

    if (!isUndoing && transferOnDelete && activity.observations.isNotEmpty) {
      const transferableTypes = {
        'Text',
        'Presenting-Complaint',
        'File',
      };

      final targetActivity = _claimData!.activities.firstWhereOrNull(
        (a) => !a.isDeleted && a.stateId != activity.stateId,
      );

      if (targetActivity != null) {
        final observationsToTransfer = activity.observations
            .where((obs) => transferableTypes.contains(obs.type))
            .toList();

        if (observationsToTransfer.isNotEmpty) {
          targetActivity.observations.addAll(observationsToTransfer);
          activity.observations
              .removeWhere((obs) => transferableTypes.contains(obs.type));
          onMessage?.call(
              '${observationsToTransfer.length} observation(s) transferred to activity ${targetActivity.code}.',
              false);
        } else {
          onMessage?.call(
              'No transferable observations (Text, Complaint, File) found.',
              true);
        }
      } else {
        onMessage?.call(
            'No other undeleted activity found. Observations will be deleted.',
            true);
      }
    }

    activity.isDeleted = !activity.isDeleted;
    _checkAllBalances();
    _validate();
    notifyListeners();
  }

  void deleteAllActivities() {
    if (_claimData == null) return;
    for (final act in _claimData!.activities) {
      act.isDeleted = true;
    }
    _checkAllBalances();
    _validate();
    notifyListeners();
  }

  void addAllActivities() {
    if (_claimData == null) return;
    for (final act in _claimData!.activities) {
      act.isDeleted = false;
    }
    _checkAllBalances();
    _validate();
    notifyListeners();
  }

  void addActivity(ActivityData activity) {
    if (_claimData != null) {
      _claimData!.activities.add(activity);
      // We also need to add a "phantom" original activity so indexes match
      _originalActivities.add(ActivityData.clone(activity));

      // Re-calculate balances
      _checkAllBalances();

      _validate();

      notifyListeners();
      onMessage?.call('Activity added successfully.', false);
    }
  }

  void autoMatchTotals() {
    if (_claimData == null) return;
    double totalNet = 0.0;
    double deletedCopay = 0.0;
    for (int i = 0; i < _claimData!.activities.length; i++) {
      final activity = _claimData!.activities[i];
      final copayVal = double.tryParse(activity.copay ?? '0.00') ?? 0.0;
      if (activity.isDeleted) {
        deletedCopay += copayVal;
      } else {
        totalNet += double.tryParse(activity.net ?? '0.00') ?? 0.0;
      }
    }
    final patientShare = max(0.0, _originalPatientShare - deletedCopay);
    netController.text = totalNet.toStringAsFixed(2);
    patientShareController.text = patientShare.toStringAsFixed(2);
    grossController.text = (totalNet + patientShare).toStringAsFixed(2);
    _checkAllBalances();
    _validate();
    notifyListeners();
  }

  void toggleRenameFile(bool? value) {
    shouldRenameFile = value ?? false;
    notifyListeners();
  }

  void toggleTransferOnDelete(bool? value) {
    transferOnDelete = value ?? false;
    onMessage?.call(
        'Transfer on delete is now ${transferOnDelete ? 'ON' : 'OFF'}.', false);
    notifyListeners();
  }

  void updateResubmissionType(String? newType) {
    if (newType == null) return;
    final resubmission = _claimData?.resubmission;
    if (resubmission != null) {
      resubmission.type = newType;
      _validate();
      notifyListeners();
    }
  }

  void addDiagnosis(String code) {
    if (_claimData == null) return;
    if (_claimData!.diagnoses.any((d) => d.code == code)) {
      onMessage?.call('Diagnosis code $code already exists.', true);
      return;
    }
    _claimData!.diagnoses.add(DiagnosisData(code: code, type: 'Secondary'));
    _validate();
    notifyListeners();
  }

  void deleteDiagnosis(String id) {
    if (_claimData == null) return;
    _claimData!.diagnoses.removeWhere((d) => d.id == id);
    if (!_claimData!.diagnoses.any((d) => d.type == 'Principal') &&
        _claimData!.diagnoses.isNotEmpty) {
      _claimData!.diagnoses.first.type = 'Principal';
    }
    _validate();
    notifyListeners();
  }

  void resetDiagnoses() {
    if (_claimData == null) return;
    _claimData!.diagnoses =
        _originalDiagnoses.map((d) => DiagnosisData.clone(d)).toList();
    _validate();
    notifyListeners();
  }

  void resetActivities() {
    if (_claimData == null) return;
    _claimData!.activities =
        _originalActivities.map((a) => ActivityData.clone(a)).toList();
    _updateControllers();
    _validate();
    notifyListeners();
  }

  String get dispositionFlag => _claimData?.dispositionFlag ?? 'PRODUCTION';

  void setDispositionFlag(String value) {
    if (_claimData == null) return;
    _claimData!.dispositionFlag = value;
    _validate();
    notifyListeners();
  }

  void setPrincipalDiagnosis(String id) {
    if (_claimData == null) return;
    for (final diag in _claimData!.diagnoses) {
      diag.type = (diag.id == id) ? 'Principal' : 'Secondary';
    }
    _validate();
    notifyListeners();
  }

  void toggleDiagnosisEditing(bool value) {
    isDiagnosisEditingEnabled = value;
    notifyListeners();
  }

  void deleteResubmissionAttachment() {
    if (_claimData?.resubmission != null) {
      _claimData!.resubmission!.attachment = null;
      onMessage?.call('Attachment removed.', false);
      notifyListeners();
    }
  }

  Future<void> addOrEditResubmissionAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        String? base64String;
        if (kIsWeb) {
          final bytes = result.files.single.bytes!;
          base64String = AttachmentHelper.encodeFromBytes(bytes);
        } else if (result.files.single.path != null) {
          base64String =
              await AttachmentHelper.encodeFromFile(result.files.single.path!);
        }

        if (base64String != null) {
          if (_claimData?.resubmission != null) {
            _claimData!.resubmission!.attachment = base64String;
            onMessage?.call('Attachment updated successfully.', false);
            notifyListeners();
          } else {
            onMessage?.call(
                'Cannot add attachment, no resubmission data exists.', true);
          }
        } else {
          onMessage?.call('Error processing file attachment.', true);
        }
      } else {
        onMessage?.call('File selection cancelled.', false);
      }
    } catch (e) {
      onMessage?.call('Error adding attachment: $e', true);
    }
  }

  Future<void> viewResubmissionAttachment(BuildContext context) async {
    if (_claimData?.resubmission?.attachment?.isNotEmpty ?? false) {
      await AttachmentHelper.viewDecodedFile(
          _claimData!.resubmission!.attachment!, context);
    } else {
      onMessage?.call('No attachment to view.', false);
    }
  }

  void addObservation(String activityStateId, ObservationData observation) {
    _claimData?.activities
        .firstWhere((a) => a.stateId == activityStateId)
        .observations
        .add(observation);
    onMessage?.call('Observation added.', false);
    notifyListeners();
  }

  void updateObservation(
      String activityStateId, ObservationData updatedObservation) {
    final activity =
        _claimData?.activities.firstWhere((a) => a.stateId == activityStateId);
    if (activity != null) {
      final index = activity.observations
          .indexWhere((o) => o.id == updatedObservation.id);
      if (index != -1) {
        activity.observations[index] = updatedObservation;
        onMessage?.call('Observation updated.', false);
        notifyListeners();
      }
    }
  }

  void deleteObservation(String activityStateId, String observationId) {
    final activity =
        _claimData?.activities.firstWhere((a) => a.stateId == activityStateId);
    if (activity != null) {
      activity.observations.removeWhere((o) => o.id == observationId);
      onMessage?.call('Observation deleted.', false);
      notifyListeners();
    }
  }

  void mergeObservations(String activityStateId, String observationType) {
    final activity =
        _claimData?.activities.firstWhere((a) => a.stateId == activityStateId);
    if (activity == null) return;

    final toMerge = activity.observations
        .where((obs) => obs.type == observationType)
        .toList();

    if (toMerge.length < 2) {
      onMessage?.call('Not enough items to merge.', true);
      return;
    }

    final mergedValue = toMerge.map((e) => e.value).join(' ; ');
    final firstToMerge = toMerge.first;

    final mergedObservation = ObservationData(
      type: firstToMerge.type,
      code: firstToMerge.code,
      value: mergedValue,
      valueType: firstToMerge.valueType,
    );

    activity.observations.removeWhere((obs) => obs.type == observationType);
    activity.observations.add(mergedObservation);

    onMessage?.call('Observations merged successfully.', false);
    notifyListeners();
  }

  void mergeAllTextObservations() {
    if (_claimData == null) return;
    int mergeCount = 0;
    const mergeableTypes = {'Text', 'Presenting-Complaint'};

    for (final activity in _claimData!.activities) {
      final obsByType = groupBy(activity.observations, (obs) => obs.type);

      for (final type in mergeableTypes) {
        if (obsByType.containsKey(type) && obsByType[type]!.length > 1) {
          final toMerge = obsByType[type]!;
          final mergedValue = toMerge.map((e) => e.value).join(' ; ');
          final firstToMerge = toMerge.first;

          final mergedObservation = ObservationData(
            type: firstToMerge.type,
            code: firstToMerge.code,
            value: mergedValue,
            valueType: firstToMerge.valueType,
          );

          activity.observations.removeWhere((obs) => obs.type == type);
          activity.observations.add(mergedObservation);
          mergeCount++;
        }
      }
    }

    if (mergeCount > 0) {
      onMessage?.call('Merged observations in $mergeCount group(s).', false);
      notifyListeners();
    } else {
      onMessage?.call('No observations found to merge.', true);
    }
  }

  @override
  void dispose() {
    grossController.dispose();
    patientShareController.dispose();
    netController.dispose();
    resubmissionCommentController.dispose();

    super.dispose();
  }
}
