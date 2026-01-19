import 'package:uuid/uuid.dart';

const List<String> claimChildOrder = [
  "ID",
  "IDPayer",
  "MemberID",
  "PayerID",
  "ProviderID",
  "Weight",
  "EmiratesIDNumber",
  "Gross",
  "PatientShare",
  "Net",
  "Encounter",
  "Diagnosis",
  "Activity",
  "Resubmission",
  "Contract"
];

class DiagnosisData {
  String id = const Uuid().v4();
  String? type;
  String? code;

  DiagnosisData({this.type, this.code});

  DiagnosisData.clone(DiagnosisData other)
      : id = other.id,
        code = other.code,
        type = other.type;
}

class ResubmissionData {
  String? type;
  String? comment;
  String? attachment;
}

class ContractData {
  String? packageName;
}

class ObservationData {
  String id = const Uuid().v4();
  String type;
  String code;
  String value;
  String valueType;

  ObservationData({
    required this.type,
    required this.code,
    required this.value,
    required this.valueType,
  });

  ObservationData.clone(ObservationData other)
      : id = other.id,
        type = other.type,
        code = other.code,
        value = other.value,
        valueType = other.valueType;
}

class ActivityData {
  String stateId = const Uuid().v4();
  String? id;
  String? start;
  String? type;
  String? code;
  String? quantity;
  String? net;
  String? clinician;
  String? priorAuthorizationID;
  String? copay;
  bool isDeleted = false;
  List<ObservationData> observations = [];

  ActivityData();

  ActivityData.clone(ActivityData other)
      : stateId = other.stateId,
        id = other.id,
        start = other.start,
        type = other.type,
        code = other.code,
        quantity = other.quantity,
        net = other.net,
        clinician = other.clinician,
        priorAuthorizationID = other.priorAuthorizationID,
        copay = other.copay,
        isDeleted = other.isDeleted,
        observations = List<ObservationData>.from(
            other.observations.map((o) => ObservationData.clone(o)));
}

class ClaimData {
  String? rawXml;
  String? senderID;
  String? receiverID;
  String? transactionDate;
  String? recordCount;
  String? dispositionFlag;
  String? claimId;
  String? idPayer;
  String? memberID;
  String? payerID;
  String? providerID;
  String? weight;
  String? emiratesIDNumber;
  String? gross;
  String? patientShare;
  String? net;
  String? facilityID;
  String? encounterType;
  String? patientId;
  String? start;
  String? end;
  String? startType;
  String? endType;
  String? transferSource;
  String? transferDestination;
  List<ActivityData> activities = [];
  List<DiagnosisData> diagnoses = [];
  ResubmissionData? resubmission;
  ContractData? contract;
}
