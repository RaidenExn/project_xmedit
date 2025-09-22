import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/helpers/platform_helper.dart';
import 'package:project_xmedit/xml_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =================== ThemeNotifier ===================
class ThemeNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor;

  static const _defaultColor = Colors.green;
  final List<Color> availableColors = const [Colors.green, Colors.blue, Colors.red, Colors.orange, Colors.purple, Colors.teal];

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  ThemeNotifier._(this._seedColor);

  static Future<ThemeNotifier> create() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('themeColor');
    final seedColor = colorValue != null ? Color(colorValue) : _defaultColor;
    final notifier = ThemeNotifier._(seedColor).._prefs = prefs;
    return notifier;
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void changeSeedColor(Color color) {
    if (_seedColor == color) return;
    _seedColor = color;
    // ignore: deprecated_member_use
    _prefs.setInt('themeColor', color.value);
    notifyListeners();
  }
}

// =================== CardVisibilityNotifier ===================
class CardVisibilityNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;
  final Map<String, bool> _visibilities = {'details': true, 'resubmission & totals': true, 'activities': true, 'diagnosis': true};

  UnmodifiableMapView<String, bool> get visibilities => UnmodifiableMapView(_visibilities);

  CardVisibilityNotifier._();

  static Future<CardVisibilityNotifier> create() async {
    final notifier = CardVisibilityNotifier._();
    notifier._prefs = await SharedPreferences.getInstance();
    for (final key in notifier._visibilities.keys) {
      notifier._visibilities[key] = notifier._prefs.getBool(key) ?? true;
    }
    return notifier;
  }

  void toggle(String key) {
    if (_visibilities.containsKey(key)) {
      _visibilities[key] = !_visibilities[key]!;
      _prefs.setBool(key, _visibilities[key]!);
      notifyListeners();
    }
  }
}

// =================== ClaimDataNotifier ===================
class ClaimDataNotifier extends ChangeNotifier {
  final _xmlHandler = XmlHandler();
  final _dbHelper = DatabaseHelper();
  ClaimData? _claimData;
  var _originalDiagnoses = <DiagnosisData>[];
  var _originalActivities = <ActivityData>[];
  bool _isLoading = false;
  String? _originalFilePath;
  double _originalPatientShare = 0.0;
  void Function(String message, bool isError)? onMessage;

  // Public state
  bool shouldRenameFile = false;
  String? originalResubmissionType;
  String grossDifference = "";
  String netDifference = "";
  Map<String, String> cptDescriptions = {};
  bool isDiagnosisEditingEnabled = false;
  bool transferOnDelete = false;

  // Controllers
  final grossController = TextEditingController();
  final patientShareController = TextEditingController();
  final netController = TextEditingController();
  final resubmissionCommentController = TextEditingController();
  var activityNetControllers = <TextEditingController>[];
  var activityCopayControllers = <TextEditingController>[];
  var activityQuantityControllers = <TextEditingController>[];
  var activityDslCodeControllers = <String, TextEditingController>{};

  ClaimData? get claimData => _claimData;
  bool get isLoading => _isLoading;
  List<ActivityData> get originalActivities => _originalActivities;

  Map<String, List<ActivityData>> get groupedActivities =>
      _claimData == null ? {} : groupBy(_claimData!.activities, (activity) => activity.type ?? 'unknown');

  ClaimDataNotifier() {
    if (!kIsWeb) _dbHelper.database;
  }

  // --- Private Helper Methods ---
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  ActivityData? _findActivityById(String activityStateId) {
    return _claimData?.activities.firstWhereOrNull((a) => a.stateId == activityStateId);
  }

  void _disposeActivityControllers() {
    final allControllers = [...activityNetControllers, ...activityCopayControllers, ...activityQuantityControllers, ...activityDslCodeControllers.values];
    for (final controller in allControllers) {
      controller.removeListener(_onControllerChanged);
      controller.dispose();
    }
    activityNetControllers.clear();
    activityCopayControllers.clear();
    activityQuantityControllers.clear();
    activityDslCodeControllers.clear();
  }

  void _setupControllers() {
    final data = _claimData;
    if (data == null) return;

    grossController.text = data.gross ?? '0.00';
    patientShareController.text = data.patientShare ?? '0.00';
    netController.text = data.net ?? '0.00';
    resubmissionCommentController.text = data.resubmission?.comment ?? '';
    _originalPatientShare = double.tryParse(data.patientShare ?? '0') ?? 0.0;
    originalResubmissionType = data.resubmission?.type;

    if (data.resubmission?.type == null || !["correction", "internal complaint", "reconciliation"].contains(data.resubmission!.type)) {
      (data.resubmission ??= ResubmissionData()).type = 'internal complaint';
    }

    for (var i = 0; i < data.activities.length; i++) {
      final activity = data.activities[i];
      final qtyController = TextEditingController(text: activity.quantity ?? '1')..addListener(() => _onQuantityChanged(i));
      activityQuantityControllers.add(qtyController);
      activityNetControllers.add(TextEditingController(text: activity.net ?? '0.00'));
      activityCopayControllers.add(TextEditingController(text: activity.copay ?? '0.00'));

      if (activity.type == '8') {
        final dslController = TextEditingController(text: activity.code ?? '');
        dslController.addListener(() => activity.code = dslController.text);
        activityDslCodeControllers[activity.stateId] = dslController;
      }
    }

    final financialControllers = [grossController, patientShareController, netController, ...activityNetControllers, ...activityCopayControllers];
    for (final c in financialControllers) {
      c.addListener(_onControllerChanged);
    }
    _checkNetBalance();
  }

  void _updateAndRefreshControllers() {
    // Dispose old listeners and controllers
    grossController.removeListener(_onControllerChanged);
    patientShareController.removeListener(_onControllerChanged);
    netController.removeListener(_onControllerChanged);
    _disposeActivityControllers();

    // Clear and setup new ones
    for (final controller in [grossController, patientShareController, netController, resubmissionCommentController]) {
        controller.clear();
    }
    _setupControllers();
  }

  void _checkNetBalance() {
    if (_claimData == null) return;
    final totalNetFromActivities = Iterable.generate(_claimData!.activities.length)
        .where((i) => !_claimData!.activities[i].isDeleted)
        .map((i) => double.tryParse(activityNetControllers[i].text) ?? 0.0)
        .sum;
    final declaredNet = double.tryParse(netController.text) ?? 0.0;
    final diff = declaredNet - totalNetFromActivities;
    netDifference = (diff.abs() > 0.001) ? "(Δ ${diff.toStringAsFixed(2)})" : "";
  }

  void _onControllerChanged() {
    _checkNetBalance();
    notifyListeners();
  }

  void _onQuantityChanged(int index) {
    if (_claimData == null || index >= _claimData!.activities.length) return;
    final originalActivity = _originalActivities[index];
    final originalQty = int.tryParse(originalActivity.quantity ?? '1') ?? 1;
    if (originalQty == 0) return;

    final originalNet = double.tryParse(originalActivity.net ?? '0.00') ?? 0.0;
    final unitPrice = originalNet / originalQty;

    final currentQtyController = activityQuantityControllers[index];
    final newQty = int.tryParse(currentQtyController.text) ?? 0;
    final newNetText = (newQty * unitPrice).toStringAsFixed(2);
    final netController = activityNetControllers[index];
    
    _claimData!.activities[index]
        ..quantity = currentQtyController.text
        ..net = newNetText;

    if (netController.text != newNetText) {
      netController.text = newNetText; // This will trigger _onControllerChanged
    } else {
      notifyListeners();
    }
  }

  // --- Public API Methods ---
  Future<void> loadXmlFile() async {
    _setLoading(true);
    cptDescriptions.clear();
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xml'], withData: true);
      if (result == null || result.files.single.bytes == null) {
        onMessage?.call('File selection cancelled.', false);
        return;
      }
      
      final xmlString = String.fromCharCodes(result.files.single.bytes!);
      _claimData = await compute(parseXmlInBackground, xmlString);
      _originalFilePath = kIsWeb ? null : result.files.single.path;
      _originalDiagnoses = _claimData!.diagnoses.map(DiagnosisData.clone).toList();
      _originalActivities = _claimData!.activities.map(ActivityData.clone).toList();
      isDiagnosisEditingEnabled = false;

      if (!kIsWeb) {
        final activityCodes = _claimData!.activities.map((a) => a.code).whereType<String>().toSet();
        cptDescriptions = await _dbHelper.getDescriptionsForCptCodes(activityCodes);
      }

      _updateAndRefreshControllers();
      onMessage?.call('XML file loaded successfully!', false);
    } on XmlParsingException catch (e) {
      onMessage?.call(e.message, true);
    } catch (e) {
      onMessage?.call('An unexpected error occurred: $e', true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveXmlFile({bool saveAs = false}) async {
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
      _claimData!.resubmission?.comment = resubmissionCommentController.text.trim();
      for (int i = 0; i < _claimData!.activities.length; i++) {
        _claimData!.activities[i].net = activityNetControllers[i].text;
      }

      final xmlString = _xmlHandler.createXmlDocument(_claimData!).toXmlString(pretty: true, indent: '  ');
      final sanitizedId = (_claimData!.claimId ?? "UNKNOWN").replaceAll(RegExp(r'[^\w-]'), '_');
      final baseFileName = _originalFilePath != null ? p.basename(_originalFilePath!) : 'output.xml';
      final finalFileName = shouldRenameFile ? 'claim_$sanitizedId.xml' : baseFileName;

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(xmlString, finalFileName);
        onMessage?.call("XML file download started.", false);
      } else {
        String? outputFile;
        if (saveAs) {
          outputFile = await FilePicker.platform.saveFile(dialogTitle: 'Save XML As...', fileName: finalFileName, allowedExtensions: ['xml']);
        } else {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir == null) throw Exception("Could not find Downloads directory.");
          outputFile = p.join(downloadsDir.path, finalFileName);
        }

        if (outputFile != null) {
          await File(outputFile).writeAsString(xmlString);
          onMessage?.call("XML file saved successfully to ${p.basename(outputFile)}", false);
        } else {
          onMessage?.call("Save operation cancelled.", false);
        }
      }

      _originalActivities = _claimData!.activities.map(ActivityData.clone).toList();
      _originalDiagnoses = _claimData!.diagnoses.map(DiagnosisData.clone).toList();
      notifyListeners();
    } catch (e) {
      onMessage?.call("Error saving file: $e", true);
    } finally {
      _setLoading(false);
    }
  }

  void clearData() {
    _claimData = null;
    _originalDiagnoses.clear();
    _originalActivities.clear();
    shouldRenameFile = false;
    grossDifference = "";
    netDifference = "";
    isDiagnosisEditingEnabled = false;
    transferOnDelete = false;
    cptDescriptions.clear();
    _updateAndRefreshControllers();
    notifyListeners();
    onMessage?.call('Data has been cleared.', false);
  }

  void toggleActivityDeleted(int index) {
    if (_claimData == null || index >= _claimData!.activities.length) return;
    final activity = _claimData!.activities[index];
    
    if (!activity.isDeleted && transferOnDelete && activity.observations.isNotEmpty) {
      final nextActivityIndex = _claimData!.activities.indexWhere((act) => !_claimData!.activities.indexOf(act).isNegative && _claimData!.activities.indexOf(act) > index && !act.isDeleted);
      if (nextActivityIndex != -1) {
        final targetActivity = _claimData!.activities[nextActivityIndex];
        targetActivity.observations.addAll(activity.observations);
        activity.observations.clear();
        onMessage?.call('Observations transferred to activity ${targetActivity.code}.', false);
      } else {
        onMessage?.call('No subsequent activity found. Observations will be deleted.', true);
      }
    }
    activity.isDeleted = !activity.isDeleted;
    _checkNetBalance();
    notifyListeners();
  }

  void deleteAllActivities() {
    _claimData?.activities.forEach((act) => act.isDeleted = true);
    _checkNetBalance();
    notifyListeners();
  }

  void addAllActivities() {
    _claimData?.activities.forEach((act) => act.isDeleted = false);
    _checkNetBalance();
    notifyListeners();
  }

  void autoMatchTotals() {
    if (_claimData == null) return;
    double totalNet = 0.0;
    double deletedCopay = 0.0;
    for (int i = 0; i < _claimData!.activities.length; i++) {
      final activity = _claimData!.activities[i];
      final copayVal = double.tryParse(activityCopayControllers[i].text) ?? 0.0;
      if (activity.isDeleted) {
        deletedCopay += copayVal;
      } else {
        totalNet += double.tryParse(activityNetControllers[i].text) ?? 0.0;
      }
    }
    final patientShare = max(0.0, _originalPatientShare - deletedCopay);
    netController.text = totalNet.toStringAsFixed(2);
    patientShareController.text = patientShare.toStringAsFixed(2);
    grossController.text = (totalNet + patientShare).toStringAsFixed(2);
    _checkNetBalance();
    notifyListeners();
  }

  void onTotalsEdited(String source) {
    final g = double.tryParse(grossController.text) ?? 0.0;
    final ps = double.tryParse(patientShareController.text) ?? 0.0;
    final n = double.tryParse(netController.text) ?? 0.0;
    if (source == "gross") {
      netController.text = (g - ps).toStringAsFixed(2);
    } else { // pshare or net
      grossController.text = (n + ps).toStringAsFixed(2);
    }
    _checkNetBalance();
    notifyListeners();
  }

  void resetActivities() {
    if (_claimData == null) return;
    _claimData!.activities = _originalActivities.map(ActivityData.clone).toList();
    _updateAndRefreshControllers();
    notifyListeners();
  }

  // --- Resubmission and Toggles ---
  void toggleRenameFile(bool? value) {
    shouldRenameFile = value ?? false;
    notifyListeners();
  }

  void toggleTransferOnDelete(bool? value) {
    transferOnDelete = value ?? false;
    onMessage?.call('Transfer on delete is now ${transferOnDelete ? 'ON' : 'OFF'}.', false);
    notifyListeners();
  }

  void updateResubmissionType(String? newType) {
    if (newType != null && _claimData?.resubmission != null) {
      _claimData!.resubmission!.type = newType;
      notifyListeners();
    }
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
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (result != null && result.files.single.bytes != null) {
        final base64String = await AttachmentHelper.encodeFromBytes(result.files.single.bytes!);
        if (_claimData?.resubmission != null) {
          _claimData!.resubmission!.attachment = base64String;
          onMessage?.call('Attachment updated successfully.', false);
          notifyListeners();
        } else {
          onMessage?.call('Cannot add attachment, no resubmission data exists.', true);
        }
      } else {
        onMessage?.call('File selection cancelled.', false);
      }
    } catch (e) {
      onMessage?.call('Error adding attachment: $e', true);
    }
  }

  Future<void> viewResubmissionAttachment(BuildContext context) async {
    final attachment = _claimData?.resubmission?.attachment;
    if (attachment?.isNotEmpty ?? false) {
      await AttachmentHelper.viewDecodedFile(attachment!, context);
    } else {
      onMessage?.call('No attachment to view.', false);
    }
  }

  // --- Diagnosis Methods ---
  void toggleDiagnosisEditing(bool value) {
    isDiagnosisEditingEnabled = value;
    notifyListeners();
  }

  void addDiagnosis(String code) {
    if (_claimData == null) return;
    if (_claimData!.diagnoses.any((d) => d.code == code)) {
      onMessage?.call('Diagnosis code $code already exists.', true);
      return;
    }
    _claimData!.diagnoses.add(DiagnosisData(code: code, type: 'Secondary'));
    notifyListeners();
  }

  void deleteDiagnosis(String id) {
    _claimData?.diagnoses.removeWhere((d) => d.id == id);
    if (_claimData != null && !_claimData!.diagnoses.any((d) => d.type == 'Principal') && _claimData!.diagnoses.isNotEmpty) {
      _claimData!.diagnoses.first.type = 'Principal';
    }
    notifyListeners();
  }

  void setPrincipalDiagnosis(String id) {
    _claimData?.diagnoses.forEach((diag) => diag.type = (diag.id == id) ? 'Principal' : 'Secondary');
    notifyListeners();
  }
  
  void resetDiagnoses() {
    if (_claimData == null) return;
    _claimData!.diagnoses = _originalDiagnoses.map(DiagnosisData.clone).toList();
    notifyListeners();
  }
  
  // --- Observation Methods ---
  void addObservation(String activityStateId, ObservationData observation) {
    _findActivityById(activityStateId)?.observations.add(observation);
    onMessage?.call('Observation added.', false);
    notifyListeners();
  }

  void updateObservation(String activityStateId, ObservationData updatedObservation) {
    final activity = _findActivityById(activityStateId);
    if (activity == null) return;
    final index = activity.observations.indexWhere((o) => o.id == updatedObservation.id);
    if (index != -1) {
      activity.observations[index] = updatedObservation;
      onMessage?.call('Observation updated.', false);
      notifyListeners();
    }
  }

  void deleteObservation(String activityStateId, String observationId) {
    _findActivityById(activityStateId)?.observations.removeWhere((o) => o.id == observationId);
    onMessage?.call('Observation deleted.', false);
    notifyListeners();
  }

  void mergeObservations(String activityStateId, String observationType) {
    final activity = _findActivityById(activityStateId);
    if (activity == null) return;
    final toMerge = activity.observations.where((obs) => obs.type == observationType).toList();
    if (toMerge.length < 2) {
      onMessage?.call('Not enough items to merge.', true);
      return;
    }

    final mergedValue = toMerge.map((e) => e.value).join(' ; ');
    final first = toMerge.first;
    final mergedObservation = ObservationData(type: first.type, code: first.code, value: mergedValue, valueType: first.valueType);
    
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
        if ((obsByType[type]?.length ?? 0) > 1) {
          final toMerge = obsByType[type]!;
          final mergedValue = toMerge.map((e) => e.value).join(' ; ');
          final first = toMerge.first;
          final mergedObservation = ObservationData(type: first.type, code: first.code, value: mergedValue, valueType: first.valueType);
          
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

  // --- Lifecycle ---
  @override
  void dispose() {
    for (final controller in [grossController, patientShareController, netController, resubmissionCommentController]) {
        controller.dispose();
    }
    _disposeActivityControllers();
    super.dispose();
  }
}