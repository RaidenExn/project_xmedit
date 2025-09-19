import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/xml_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.green;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  final List<Color> _availableColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  List<Color> get availableColors => _availableColors;

  ThemeNotifier() {
    _loadPreferences();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _savePreferences();
    notifyListeners();
  }

  void changeSeedColor(Color color) {
    _seedColor = color;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final int? colorValue = _prefs.getInt('themeColor');
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    await _prefs.setInt('themeColor', _seedColor.value);
  }
}

class CardVisibilityNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;

  final Map<String, bool> _visibilities = {
    'details': true,
    'controls & totals': true,
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

class ClaimDataNotifier extends ChangeNotifier {
  final XmlHandler _xmlHandler = XmlHandler();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  ClaimData? _claimData;
  List<DiagnosisData> _originalDiagnoses = [];
  List<ActivityData> _originalActivities = [];
  bool _isLoading = false;
  String? _originalFilePath;
  double _originalPatientShare = 0.0;
  void Function(String message, bool isError)? onMessage;

  bool shouldRenameFile = false;
  String? originalResubmissionType;
  String grossDifference = "";
  String netDifference = "";
  Map<String, String> _cptDescriptions = {};
  bool isDiagnosisEditingEnabled = false;

  final TextEditingController grossController = TextEditingController();
  final TextEditingController patientShareController = TextEditingController();
  final TextEditingController netController = TextEditingController();
  final TextEditingController resubmissionCommentController =
      TextEditingController();

  List<TextEditingController> activityNetControllers = [];
  List<TextEditingController> activityCopayControllers = [];
  Map<String, TextEditingController> activityDslCodeControllers = {};

  ClaimDataNotifier() {
    _dbHelper.database;
  }

  Map<String, String> get cptDescriptions => _cptDescriptions;
  ClaimData? get claimData => _claimData;
  bool get isLoading => _isLoading;

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
    // Hold references to the old controllers
    final oldNetControllers = activityNetControllers;
    final oldCopayControllers = activityCopayControllers;
    final oldDslCodeControllers = activityDslCodeControllers;

    // Immediately create and assign new empty lists
    activityNetControllers = [];
    activityCopayControllers = [];
    activityDslCodeControllers = {};

    // Remove listeners from permanent controllers
    grossController.removeListener(_onControllerChanged);
    patientShareController.removeListener(_onControllerChanged);
    netController.removeListener(_onControllerChanged);
    
    // Dispose the old controllers safely
    for (final c in [...oldNetControllers, ...oldCopayControllers]) {
      c.removeListener(_onControllerChanged);
      c.dispose();
    }
    for (final c in oldDslCodeControllers.values) {
      c.dispose();
    }

    _clearPermanentControllers();

    if (_claimData != null) {
      grossController.text = _claimData!.gross ?? '0.00';
      patientShareController.text = _claimData!.patientShare ?? '0.00';
      netController.text = _claimData!.net ?? '0.00';
      resubmissionCommentController.text =
          _claimData!.resubmission?.comment ?? '';
      _originalPatientShare =
          double.tryParse(_claimData!.patientShare ?? '0') ?? 0.0;
      originalResubmissionType = _claimData!.resubmission?.type;
      
      const resubmissionOptions = ["correction", "internal complaint", "reconciliation"];
      final currentType = _claimData!.resubmission?.type;
      if (currentType == null || !resubmissionOptions.contains(currentType)) {
        (_claimData!.resubmission ??= ResubmissionData()).type = 'internal complaint';
      }

      for (final activity in _claimData!.activities) {
        activityNetControllers.add(TextEditingController(text: activity.net ?? '0.00'));
        activityCopayControllers.add(TextEditingController(text: activity.copay ?? '0.00'));

        if (activity.type == '8') {
          final controller = TextEditingController(text: activity.code ?? '');
          controller.addListener(() => activity.code = controller.text);
          activityDslCodeControllers[activity.stateId] = controller;
        }
      }

      for (final c in [
        grossController,
        patientShareController,
        netController,
        ...activityNetControllers,
        ...activityCopayControllers
      ]) {
        c.addListener(_onControllerChanged);
      }
      _checkAllBalances();
    }
  }

  void _onControllerChanged() {
    _checkAllBalances();
    notifyListeners();
  }

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
    final totalNetFromActivities = Iterable.generate(_claimData!.activities.length)
        .where((i) => !_claimData!.activities[i].isDeleted)
        .map((i) => double.tryParse(activityNetControllers[i].text) ?? 0.0)
        .fold(0.0, (prev, val) => prev + val);
    final declaredNet = double.tryParse(netController.text) ?? 0.0;
    final diff = declaredNet - totalNetFromActivities;
    netDifference = (diff.abs() > 0.001) ? "(Δ ${diff.toStringAsFixed(2)})" : "";
  }

  void _checkAllBalances() => _checkNetBalance();

  Future<void> loadXmlFile() async {
    _setLoading(true);
    try {
      final result = await _xmlHandler.loadXmlFile();
      if (result != null) {
        _claimData = result.$1;
        _originalFilePath = result.$2;
        _originalDiagnoses = _claimData!.diagnoses.map((d) => DiagnosisData.clone(d)).toList();
        _originalActivities = _claimData!.activities.map((a) => ActivityData.clone(a)).toList();
        isDiagnosisEditingEnabled = false;
        final activityCodes = _claimData!.activities.map((a) => a.code).whereType<String>().toSet();
        _cptDescriptions = await _dbHelper.getDescriptionsForCptCodes(activityCodes);
        _updateControllers();
        onMessage?.call('XML file loaded successfully!', false);
      } else {
        onMessage?.call('File selection cancelled.', false);
      }
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
      if (_claimData!.resubmission != null) {
        _claimData!.resubmission!.comment = resubmissionCommentController.text.trim();
      }
      for (int i = 0; i < _claimData!.activities.length; i++) {
        _claimData!.activities[i].net = activityNetControllers[i].text;
      }
      final xmlString = _xmlHandler.createXmlDocument(_claimData!).toXmlString(pretty: true, indent: '  ');
      String? outputFile;
      final claimId = _claimData!.claimId ?? "UNKNOWN";
      final sanitizedId = claimId.replaceAll(RegExp(r'[^\w-]'), '_');
      final baseFileName = _originalFilePath != null ? p.basename(_originalFilePath!) : 'output.xml';
      final finalFileName = shouldRenameFile ? 'claim_$sanitizedId.xml' : baseFileName;
      if (saveAs) {
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: finalFileName,
          type: FileType.custom,
          allowedExtensions: ['xml'],
        );
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
    _cptDescriptions.clear();
    _updateControllers();
    notifyListeners();
    onMessage?.call('Data has been cleared.', false);
  }

  void toggleActivityDeleted(int index) {
    if (_claimData == null || index >= _claimData!.activities.length) return;
    _claimData!.activities[index].isDeleted = !_claimData!.activities[index].isDeleted;
    _checkAllBalances();
    notifyListeners();
  }

  void deleteAllActivities() {
    if (_claimData == null) return;
    for (final act in _claimData!.activities) {
      act.isDeleted = true;
    }
    _checkAllBalances();
    notifyListeners();
  }

  void addAllActivities() {
    if (_claimData == null) return;
    for (final act in _claimData!.activities) {
      act.isDeleted = false;
    }
    _checkAllBalances();
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
    _checkAllBalances();
    notifyListeners();
  }

  void toggleRenameFile(bool? value) {
    shouldRenameFile = value ?? false;
    notifyListeners();
  }

  void updateResubmissionType(String? newType) {
    if (newType != null && _claimData?.resubmission != null) {
      _claimData!.resubmission!.type = newType;
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
    notifyListeners();
  }

  void deleteDiagnosis(String id) {
    if (_claimData == null) return;
    _claimData!.diagnoses.removeWhere((d) => d.id == id);
    if (!_claimData!.diagnoses.any((d) => d.type == 'Principal') && _claimData!.diagnoses.isNotEmpty) {
      _claimData!.diagnoses.first.type = 'Principal';
    }
    notifyListeners();
  }

  void resetDiagnoses() {
    if (_claimData == null) return;
    _claimData!.diagnoses = _originalDiagnoses.map((d) => DiagnosisData.clone(d)).toList();
    notifyListeners();
  }

  void resetActivities() {
    if (_claimData == null) return;
    _claimData!.activities = _originalActivities.map((a) => ActivityData.clone(a)).toList();
    _updateControllers(); // Rebuilds all controllers
    notifyListeners(); // Notify UI to rebuild with new data/controllers
  }

  void setPrincipalDiagnosis(String id) {
    if (_claimData == null) return;
    for (final diag in _claimData!.diagnoses) {
      diag.type = (diag.id == id) ? 'Principal' : 'Secondary';
    }
    notifyListeners();
  }

  void toggleDiagnosisEditing(bool value) {
    isDiagnosisEditingEnabled = value;
    notifyListeners();
  }

  @override
  void dispose() {
    grossController.dispose();
    patientShareController.dispose();
    netController.dispose();
    resubmissionCommentController.dispose();
    
    for (final c in [...activityNetControllers, ...activityCopayControllers]) {
      c.dispose();
    }
    for (final c in activityDslCodeControllers.values) {
      c.dispose();
    }

    super.dispose();
  }
}