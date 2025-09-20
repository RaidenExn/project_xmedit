import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class XmlParsingException implements Exception {
  final String message;
  XmlParsingException(this.message);
}

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

ClaimData parseXmlInBackground(String xmlString) {
  XmlDocument document;
  try {
    document = XmlDocument.parse(xmlString);
  } on XmlException {
    throw XmlParsingException('The selected file is not a valid XML format.');
  }
  final root = document.rootElement;
  if (root.name.local != 'Claim.Submission') {
    throw XmlParsingException('XML is not a submission file.');
  }
  final claimData = ClaimData();
  claimData.rawXml = xmlString;
  final header = document.findAllElements('Header').firstOrNull;
  if (header != null) {
    claimData.senderID =
        header.findAllElements('SenderID').firstOrNull?.innerText;
    claimData.receiverID =
        header.findAllElements('ReceiverID').firstOrNull?.innerText;
    claimData.transactionDate =
        header.findAllElements('TransactionDate').firstOrNull?.innerText;
    claimData.recordCount =
        header.findAllElements('RecordCount').firstOrNull?.innerText;
    claimData.dispositionFlag =
        header.findAllElements('DispositionFlag').firstOrNull?.innerText;
  }
  final claimElement = document.findAllElements('Claim').firstOrNull;
  if (claimElement == null) {
    throw XmlParsingException('Claim element not found in the XML.');
  }
  claimData.claimId = claimElement.findAllElements('ID').firstOrNull?.innerText;
  claimData.idPayer =
      claimElement.findAllElements('IDPayer').firstOrNull?.innerText;
  claimData.memberID =
      claimElement.findAllElements('MemberID').firstOrNull?.innerText;
  claimData.payerID =
      claimElement.findAllElements('PayerID').firstOrNull?.innerText;
  claimData.providerID =
      claimElement.findAllElements('ProviderID').firstOrNull?.innerText;
  claimData.weight =
      claimElement.findAllElements('Weight').firstOrNull?.innerText;
  claimData.emiratesIDNumber =
      claimElement.findAllElements('EmiratesIDNumber').firstOrNull?.innerText;
  claimData.gross = claimElement.findAllElements('Gross').firstOrNull?.innerText;
  claimData.patientShare =
      claimElement.findAllElements('PatientShare').firstOrNull?.innerText;
  claimData.net = claimElement.findAllElements('Net').firstOrNull?.innerText;
  final encounter = claimElement.findAllElements('Encounter').firstOrNull;
  if (encounter != null) {
    claimData.facilityID =
        encounter.findAllElements('FacilityID').firstOrNull?.innerText;
    claimData.encounterType =
        encounter.findAllElements('Type').firstOrNull?.innerText;
    claimData.patientId =
        encounter.findAllElements('PatientID').firstOrNull?.innerText;
    claimData.start = encounter.findAllElements('Start').firstOrNull?.innerText;
    claimData.end = encounter.findAllElements('End').firstOrNull?.innerText;
    claimData.startType =
        encounter.findAllElements('StartType').firstOrNull?.innerText;
    claimData.endType =
        encounter.findAllElements('EndType').firstOrNull?.innerText;
    claimData.transferSource =
        encounter.findAllElements('TransferSource').firstOrNull?.innerText;
    claimData.transferDestination =
        encounter.findAllElements('TransferDestination').firstOrNull?.innerText;
  }

  for (final diagnosis in document.findAllElements('Diagnosis')) {
    final diagnosisData = DiagnosisData(
        type: diagnosis.findAllElements('Type').firstOrNull?.innerText,
        code: diagnosis.findAllElements('Code').firstOrNull?.innerText);
    claimData.diagnoses.add(diagnosisData);
  }

  for (final activity in document.findAllElements('Activity')) {
    final activityData = ActivityData();
    activityData.id = activity.findAllElements('ID').firstOrNull?.innerText;
    activityData.start =
        activity.findAllElements('Start').firstOrNull?.innerText;
    activityData.type = activity.findAllElements('Type').firstOrNull?.innerText;
    activityData.code = activity.findAllElements('Code').firstOrNull?.innerText;
    activityData.quantity =
        activity.findAllElements('Quantity').firstOrNull?.innerText;
    activityData.net = activity.findAllElements('Net').firstOrNull?.innerText;
    activityData.clinician =
        activity.findAllElements('Clinician').firstOrNull?.innerText;
    activityData.priorAuthorizationID =
        activity.findAllElements('PriorAuthorizationID').firstOrNull?.innerText;
    activityData.copay =
        activity.findAllElements('Copay').firstOrNull?.innerText;
    for (final observation in activity.findAllElements('Observation')) {
      activityData.observations.add(ObservationData(
        type: observation.findAllElements('Type').firstOrNull?.innerText ?? '',
        code: observation.findAllElements('Code').firstOrNull?.innerText ?? '',
        value:
            observation.findAllElements('Value').firstOrNull?.innerText ?? '',
        valueType:
            observation.findAllElements('ValueType').firstOrNull?.innerText ??
                '',
      ));
    }
    claimData.activities.add(activityData);
  }
  final resubmission = document.findAllElements('Resubmission').firstOrNull;
  if (resubmission != null) {
    final resubmissionData = ResubmissionData();
    resubmissionData.type =
        resubmission.findAllElements('Type').firstOrNull?.innerText;
    resubmissionData.comment =
        resubmission.findAllElements('Comment').firstOrNull?.innerText;

    final attachmentText =
        resubmission.findAllElements('Attachment').firstOrNull?.innerText;
    if (attachmentText != null) {
      resubmissionData.attachment =
          attachmentText.replaceAll(RegExp(r'\s+'), '');
    }

    claimData.resubmission = resubmissionData;
  }
  final contract = document.findAllElements('Contract').firstOrNull;
  if (contract != null) {
    final contractData = ContractData();
    contractData.packageName =
        contract.findAllElements('PackageName').firstOrNull?.innerText;
    claimData.contract = contractData;
  }
  return claimData;
}

class XmlHandler {
  XmlElement _buildElement(String name, String? value) {
    return XmlElement(XmlName(name), [], [if (value != null) XmlText(value)]);
  }

  XmlDocument createXmlDocument(ClaimData data) {
    final processingInstruction =
        XmlProcessing('xml', 'version="1.0" encoding="UTF-8"');

    final header = XmlElement(XmlName('Header'), [], [
      _buildElement('SenderID', data.senderID),
      _buildElement('ReceiverID', data.receiverID),
      _buildElement('TransactionDate', data.transactionDate),
      _buildElement('RecordCount', data.recordCount ?? '0'),
      _buildElement('DispositionFlag', data.dispositionFlag),
    ]);

    final Map<String, List<XmlElement>> claimChildren = {};

    void addChild(String tag, XmlElement element) {
      if (!claimChildren.containsKey(tag)) {
        claimChildren[tag] = [];
      }
      claimChildren[tag]!.add(element);
    }

    addChild('ID', _buildElement('ID', data.claimId));
    if (data.idPayer != null) {
      addChild('IDPayer', _buildElement('IDPayer', data.idPayer));
    }
    if (data.memberID != null) {
      addChild('MemberID', _buildElement('MemberID', data.memberID));
    }
    addChild('PayerID', _buildElement('PayerID', data.payerID));
    addChild('ProviderID', _buildElement('ProviderID', data.providerID));
    if (data.weight != null) {
      addChild('Weight', _buildElement('Weight', data.weight));
    }
    addChild('EmiratesIDNumber',
        _buildElement('EmiratesIDNumber', data.emiratesIDNumber));
    addChild('Gross', _buildElement('Gross', data.gross ?? '0'));
    addChild(
        'PatientShare', _buildElement('PatientShare', data.patientShare ?? '0'));
    addChild('Net', _buildElement('Net', data.net ?? '0'));

    final encounter = XmlElement(XmlName('Encounter'), [], [
      _buildElement('FacilityID', data.facilityID),
      _buildElement('Type', data.encounterType),
      _buildElement('PatientID', data.patientId),
      _buildElement('Start', data.start),
      if (data.end != null) _buildElement('End', data.end),
      if (data.startType != null) _buildElement('StartType', data.startType),
      if (data.endType != null) _buildElement('EndType', data.endType),
      if (data.transferSource != null)
        _buildElement('TransferSource', data.transferSource),
      if (data.transferDestination != null)
        _buildElement('TransferDestination', data.transferDestination),
    ]);
    addChild('Encounter', encounter);

    for (final diagnosis in data.diagnoses) {
      addChild(
          'Diagnosis',
          XmlElement(XmlName('Diagnosis'), [], [
            _buildElement('Type', diagnosis.type),
            _buildElement('Code', diagnosis.code),
          ]));
    }

    for (final activity in data.activities) {
      if (activity.isDeleted) continue;
      final activityChildren = [
        _buildElement('ID', activity.id),
        _buildElement('Start', activity.start),
        _buildElement('Type', activity.type),
        _buildElement('Code', activity.code),
        _buildElement('Quantity', activity.quantity),
        _buildElement('Net', activity.net),
        _buildElement('Clinician', activity.clinician),
        if (activity.priorAuthorizationID != null)
          _buildElement('PriorAuthorizationID', activity.priorAuthorizationID),
      ];
      for (final obs in activity.observations) {
        activityChildren.add(XmlElement(XmlName('Observation'), [], [
          _buildElement('Type', obs.type),
          _buildElement('Code', obs.code),
          if (obs.value.isNotEmpty) _buildElement('Value', obs.value),
          if (obs.valueType.isNotEmpty)
            _buildElement('ValueType', obs.valueType),
        ]));
      }
      addChild(
          'Activity', XmlElement(XmlName('Activity'), [], activityChildren));
    }

    if (data.resubmission != null) {
      final resubmissionChildren = [
        _buildElement('Type', data.resubmission!.type),
        _buildElement('Comment', data.resubmission!.comment),
      ];
      if (data.resubmission!.attachment != null) {
        resubmissionChildren
            .add(_buildElement('Attachment', data.resubmission!.attachment));
      }
      addChild('Resubmission',
          XmlElement(XmlName('Resubmission'), [], resubmissionChildren));
    }

    if (data.contract != null && data.contract!.packageName != null) {
      addChild(
          'Contract',
          XmlElement(XmlName('Contract'), [],
              [_buildElement('PackageName', data.contract!.packageName)]));
    }

    final List<XmlElement> orderedClaimChildren = [];
    for (final tag in claimChildOrder) {
      if (claimChildren.containsKey(tag)) {
        orderedClaimChildren.addAll(claimChildren[tag]!);
      }
    }

    final claim = XmlElement(XmlName('Claim'), [], orderedClaimChildren);

    final submission = XmlElement(
        XmlName('Claim.Submission'),
        [
          XmlAttribute(
              XmlName('xmlns:xsi'), 'http://www.w3.org/2001/XMLSchema-instance')
        ],
        [header, claim]);

    return XmlDocument([processingInstruction, submission]);
  }
}

class AttachmentHelper {
  static Future<String> encodeFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at path: $filePath');
    }
    final Uint8List fileBytes = await file.readAsBytes();
    return base64Encode(fileBytes);
  }

  static Future<File> decodeToTempFile(String base64Content) async {
    final Uint8List bytes = base64Decode(base64Content);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/attachment_preview.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> viewDecodedFile(
      String base64Content, BuildContext context) async {
    try {
      final file = await decodeToTempFile(base64Content);
      if (!await launchUrl(file.uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch ${file.uri}');
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