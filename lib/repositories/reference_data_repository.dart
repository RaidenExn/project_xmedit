import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';

class ReferenceDataRepository {
  static final ReferenceDataRepository _instance =
      ReferenceDataRepository._internal();

  factory ReferenceDataRepository() => _instance;

  ReferenceDataRepository._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final Map<String, Future<String?>> _payerNameFutureCache = {};
  final Map<String, Future<ClinicianProfile?>> _clinicianProfileFutureCache =
      {};
  final Map<String, Future<CodeDescription?>> _icdFutureCache = {};

  Future<void> warmup() => _db.warmupCoreReferenceData();

  Future<Map<String, CodeDescription>> getActivityDescriptions(
      List<ActivityData> activities) {
    return _db.getDescriptionsForActivities(activities);
  }

  Future<CodeDescription?> getIcdDescription(String code) {
    final key = code.trim().toUpperCase();
    if (key.isEmpty) return Future.value(null);
    return _icdFutureCache.putIfAbsent(
      key,
      () => _db.getIcd10DescriptionData(key),
    );
  }

  Future<Map<String, CodeDescription>> getIcdDescriptions(Set<String> codes) {
    return _db.getIcd10Descriptions(codes);
  }

  Future<List<MapEntry<String, String>>> searchIcd10(String query) {
    return _db.searchIcd10(query);
  }

  Future<String?> getPayerName(String payerId) {
    final key = payerId.trim().toUpperCase();
    if (key.isEmpty) return Future.value(null);
    return _payerNameFutureCache.putIfAbsent(
      key,
      () => _db.getPayerName(key),
    );
  }

  Future<String?> getClinicianName(String clinicianId) {
    return _db.getClinicianName(clinicianId);
  }

  Future<ClinicianProfile?> getClinicianProfile(String clinicianId) {
    final key = clinicianId.trim().toUpperCase();
    if (key.isEmpty) return Future.value(null);
    return _clinicianProfileFutureCache.putIfAbsent(
      key,
      () => _db.getClinicianProfile(key),
    );
  }

  void clearRuntimeCaches() {
    _payerNameFutureCache.clear();
    _clinicianProfileFutureCache.clear();
    _icdFutureCache.clear();
  }
}
