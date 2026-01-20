import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/repositories/claim_repository.dart';
import 'package:project_xmedit/services/xml_service.dart'
    show XmlParsingException, detectBulkXml;
import 'package:project_xmedit/utils/attachment_helper.dart';
import 'package:project_xmedit/services/logger.dart';
import 'package:project_xmedit/services/preferences_service.dart';
import 'package:project_xmedit/services/xml_validator.dart';
import 'package:project_xmedit/models/validation_result.dart';

class ClaimDataNotifier extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ClaimRepository _repository = ClaimRepository();

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

  void setGross(String value) {
    if (_claimData != null) {
      _claimData!.gross = value;
      _checkAllBalances();
      _validate();
      notifyListeners();
    }
  }

  void setPatientShare(String value) {
    if (_claimData != null) {
      _claimData!.patientShare = value;
      _checkAllBalances();
      _validate();
      notifyListeners();
    }
  }

  void setNet(String value) {
    if (_claimData != null) {
      _claimData!.net = value;
      _checkAllBalances();
      _validate();
      notifyListeners();
    }
  }

  void setResubmissionComment(String value) {
    if (_claimData?.resubmission != null) {
      _claimData!.resubmission!.comment = value;
      // notifyListeners(); // Only if we want to validate immediately
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

  String? updateActivityQuantity(int index, String newQuantityText) {
    if (_claimData == null || index >= _claimData!.activities.length) {
      return null;
    }

    final originalActivity = _originalActivities[index];
    final originalQty = int.tryParse(originalActivity.quantity ?? '1') ?? 1;
    final originalNet = double.tryParse(originalActivity.net ?? '0.00') ?? 0.0;

    _claimData!.activities[index].quantity = newQuantityText;

    if (originalQty == 0) {
      notifyListeners();
      return null;
    }

    final unitPrice = originalNet / originalQty;
    final newQty = int.tryParse(newQuantityText) ?? 0;
    final newNet = newQty * unitPrice;
    final newNetText = newNet.toStringAsFixed(2);

    _claimData!.activities[index].net = newNetText;

    checkBalances();
    _validate();
    notifyListeners();

    return newNetText;
  }

  void _checkNetBalance() {
    if (_claimData == null) return;
    final totalNetFromActivities = _claimData!.activities
        .where((activity) => !activity.isDeleted)
        .map((activity) => double.tryParse(activity.net ?? '0.00') ?? 0.0)
        .fold(0.0, (prev, val) => prev + val);

    final declaredNet = double.tryParse(_claimData!.net ?? '0') ?? 0.0;

    final diff = declaredNet - totalNetFromActivities;
    netDifference =
        (diff.abs() > 0.001) ? "(Δ ${diff.toStringAsFixed(2)})" : "";
  }

  void _validate() {
    if (_claimData != null) {
      _validationResult = XmlValidator.validateClaim(_claimData!);
    } else {
      _validationResult = null;
    }
  }

  void _checkAllBalances() => _checkNetBalance();

  void checkBalances() => _checkAllBalances();

  Future<void> loadXmlFile() async {
    bool loadingStarted = false;
    try {
      final FilePickResult? result = await _repository.pickXmlFile();

      if (result != null) {
        _setLoading(true);
        loadingStarted = true;
        await loadFromXmlString(result.xmlString, result.filePath);
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

      final claimData = await _repository.parseXml(xmlString);

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

      _checkAllBalances();
      _validate();

      // Log and add to recent files
      if (filePath != null) {
        AppLogger.logFileOperation('Loaded XML', filePath);
        await PreferencesService.addRecentFile(filePath);
      }

      onMessage?.call('XML file loaded successfully!', false);
    } catch (e) {
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

      final xmlString = await _repository.generateXml(_claimData!);

      final claimId = _claimData!.claimId ?? "UNKNOWN";
      final sanitizedId = claimId.replaceAll(RegExp(r'[^\w-]'), '_');
      final baseFileName = _originalFilePath != null
          ? p.basename(_originalFilePath!)
          : 'output.xml';
      final finalFileName = customFileName ??
          (shouldRenameFile ? 'claim_$sanitizedId.xml' : baseFileName);

      try {
        await _repository.saveFile(
            xmlString: xmlString, fileName: finalFileName, saveAs: saveAs);

        // If save successful (no exception)
        if (!kIsWeb) {
          onMessage?.call(
              "XML file saved successfully to $finalFileName", false);
        } else {
          onMessage?.call("Download started for $finalFileName", false);
        }

        _originalActivities =
            _claimData!.activities.map((a) => ActivityData.clone(a)).toList();
        _originalDiagnoses =
            _claimData!.diagnoses.map((d) => DiagnosisData.clone(d)).toList();
        notifyListeners();
      } on UserCancelledException {
        onMessage?.call("Save operation cancelled.", false);
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

    // Update model directly
    _claimData!.net = totalNet.toStringAsFixed(2);
    _claimData!.patientShare = patientShare.toStringAsFixed(2);
    _claimData!.gross = (totalNet + patientShare).toStringAsFixed(2);
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
      final base64String = await _repository.pickPdfFile();

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
}
