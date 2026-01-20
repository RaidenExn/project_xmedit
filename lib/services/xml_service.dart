import 'package:xml/xml.dart';
import 'package:collection/collection.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/models/bulk_claim_models.dart';

class XmlParsingException implements Exception {
  final String message;
  XmlParsingException(this.message);
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
  claimData.gross =
      claimElement.findAllElements('Gross').firstOrNull?.innerText;
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

String generateXmlString(ClaimData data) {
  XmlElement buildElement(String name, String? value) {
    return XmlElement(XmlName(name), [], [if (value != null) XmlText(value)]);
  }

  final processingInstruction =
      XmlProcessing('xml', 'version="1.0" encoding="UTF-8"');

  final header = XmlElement(XmlName('Header'), [], [
    buildElement('SenderID', data.senderID),
    buildElement('ReceiverID', data.receiverID),
    buildElement('TransactionDate', data.transactionDate),
    buildElement('RecordCount', data.recordCount ?? '0'),
    buildElement('DispositionFlag', data.dispositionFlag),
  ]);

  final Map<String, List<XmlElement>> claimChildren = {};

  void addChild(String tag, XmlElement element) {
    if (!claimChildren.containsKey(tag)) {
      claimChildren[tag] = [];
    }
    claimChildren[tag]!.add(element);
  }

  addChild('ID', buildElement('ID', data.claimId));
  if (data.idPayer != null) {
    addChild('IDPayer', buildElement('IDPayer', data.idPayer));
  }
  if (data.memberID != null) {
    addChild('MemberID', buildElement('MemberID', data.memberID));
  }
  addChild('PayerID', buildElement('PayerID', data.payerID));
  addChild('ProviderID', buildElement('ProviderID', data.providerID));
  if (data.weight != null) {
    addChild('Weight', buildElement('Weight', data.weight));
  }
  addChild('EmiratesIDNumber',
      buildElement('EmiratesIDNumber', data.emiratesIDNumber));
  addChild('Gross', buildElement('Gross', data.gross ?? '0'));
  addChild(
      'PatientShare', buildElement('PatientShare', data.patientShare ?? '0'));
  addChild('Net', buildElement('Net', data.net ?? '0'));

  final encounter = XmlElement(XmlName('Encounter'), [], [
    buildElement('FacilityID', data.facilityID),
    buildElement('Type', data.encounterType),
    buildElement('PatientID', data.patientId),
    buildElement('Start', data.start),
    if (data.end != null) buildElement('End', data.end),
    if (data.startType != null) buildElement('StartType', data.startType),
    if (data.endType != null) buildElement('EndType', data.endType),
    if (data.transferSource != null)
      buildElement('TransferSource', data.transferSource),
    if (data.transferDestination != null)
      buildElement('TransferDestination', data.transferDestination),
  ]);
  addChild('Encounter', encounter);

  for (final diagnosis in data.diagnoses) {
    addChild(
        'Diagnosis',
        XmlElement(XmlName('Diagnosis'), [], [
          buildElement('Type', diagnosis.type),
          buildElement('Code', diagnosis.code),
        ]));
  }

  for (final activity in data.activities) {
    if (activity.isDeleted) continue;
    final activityChildren = [
      buildElement('ID', activity.id),
      buildElement('Start', activity.start),
      buildElement('Type', activity.type),
      buildElement('Code', activity.code),
      buildElement('Quantity', activity.quantity),
      buildElement('Net', activity.net),
      buildElement('Clinician', activity.clinician),
      if (activity.priorAuthorizationID != null)
        buildElement('PriorAuthorizationID', activity.priorAuthorizationID),
    ];
    for (final obs in activity.observations) {
      activityChildren.add(XmlElement(XmlName('Observation'), [], [
        buildElement('Type', obs.type),
        buildElement('Code', obs.code),
        if (obs.value.isNotEmpty) buildElement('Value', obs.value),
        if (obs.valueType.isNotEmpty) buildElement('ValueType', obs.valueType),
      ]));
    }
    addChild('Activity', XmlElement(XmlName('Activity'), [], activityChildren));
  }

  if (data.resubmission != null) {
    final resubmissionChildren = [
      buildElement('Type', data.resubmission!.type),
      buildElement('Comment', data.resubmission!.comment),
    ];
    if (data.resubmission!.attachment != null) {
      resubmissionChildren
          .add(buildElement('Attachment', data.resubmission!.attachment));
    }
    addChild('Resubmission',
        XmlElement(XmlName('Resubmission'), [], resubmissionChildren));
  }

  if (data.contract != null && data.contract!.packageName != null) {
    addChild(
        'Contract',
        XmlElement(XmlName('Contract'), [],
            [buildElement('PackageName', data.contract!.packageName)]));
  }

  final List<XmlElement> orderedClaimChildren = [];
  for (final tag in claimChildOrder) {
    if (claimChildren.containsKey(tag)) {
      orderedClaimChildren.addAll(claimChildren[tag]!);
    }
  }

  final claim = XmlElement(XmlName('Claim'), [], orderedClaimChildren);

  final submission = XmlElement(XmlName('Claim.Submission'), [
    XmlAttribute(
        XmlName('xmlns:xsi'), 'http://www.w3.org/2001/XMLSchema-instance')
  ], [
    header,
    claim
  ]);

  return XmlDocument([processingInstruction, submission])
      .toXmlString(pretty: true, indent: '  ');
}

/// Detect if XML contains multiple claims (bulk XML)
bool detectBulkXml(String xmlString) {
  try {
    final document = XmlDocument.parse(xmlString);
    final claimElements = document.findAllElements('Claim');
    return claimElements.length > 1;
  } catch (e) {
    return false;
  }
}

/// Parse bulk XML containing multiple claims
/// This is a top-level function for isolate compatibility
BulkClaimData parseBulkXmlInBackground(String xmlString) {
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

  final bulkData = BulkClaimData();
  bulkData.rawXml = xmlString;

  // Parse shared header
  final header = document.findAllElements('Header').firstOrNull;
  if (header != null) {
    bulkData.senderID =
        header.findAllElements('SenderID').firstOrNull?.innerText;
    bulkData.receiverID =
        header.findAllElements('ReceiverID').firstOrNull?.innerText;
    bulkData.transactionDate =
        header.findAllElements('TransactionDate').firstOrNull?.innerText;
    bulkData.recordCount =
        header.findAllElements('RecordCount').firstOrNull?.innerText;
    bulkData.dispositionFlag =
        header.findAllElements('DispositionFlag').firstOrNull?.innerText;
  }

  // Parse all claim elements
  final claimElements = document.findAllElements('Claim').toList();
  if (claimElements.isEmpty) {
    throw XmlParsingException('No Claim elements found in the XML.');
  }

  for (final claimElement in claimElements) {
    final claimData = _parseClaimElement(claimElement);
    // Copy header data to each claim
    claimData.senderID = bulkData.senderID;
    claimData.receiverID = bulkData.receiverID;
    claimData.transactionDate = bulkData.transactionDate;
    claimData.dispositionFlag = bulkData.dispositionFlag;
    bulkData.claims.add(claimData);
  }

  return bulkData;
}

/// Helper function to parse a single claim element
ClaimData _parseClaimElement(XmlElement claimElement) {
  final claimData = ClaimData();
  claimData.rawXml = claimElement.toXmlString();

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
  claimData.gross =
      claimElement.findAllElements('Gross').firstOrNull?.innerText;
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
    claimData.transferDestination = claimElement
        .findAllElements('TransferDestination')
        .firstOrNull
        ?.innerText;
  }

  for (final diagnosis in claimElement.findAllElements('Diagnosis')) {
    final diagnosisData = DiagnosisData(
      type: diagnosis.findAllElements('Type').firstOrNull?.innerText,
      code: diagnosis.findAllElements('Code').firstOrNull?.innerText,
    );
    claimData.diagnoses.add(diagnosisData);
  }

  for (final activity in claimElement.findAllElements('Activity')) {
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

  final resubmission = claimElement.findAllElements('Resubmission').firstOrNull;
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

  final contract = claimElement.findAllElements('Contract').firstOrNull;
  if (contract != null) {
    final contractData = ContractData();
    contractData.packageName =
        contract.findAllElements('PackageName').firstOrNull?.innerText;
    claimData.contract = contractData;
  }

  return claimData;
}

/// Generate bulk XML string from BulkClaimData
String generateBulkXmlString(BulkClaimData bulkData) {
  XmlElement buildElement(String name, String? value) {
    return XmlElement(XmlName(name), [], [if (value != null) XmlText(value)]);
  }

  final processingInstruction =
      XmlProcessing('xml', 'version="1.0" encoding="UTF-8"');

  // Build header
  final header = XmlElement(XmlName('Header'), [], [
    buildElement('SenderID', bulkData.senderID),
    buildElement('ReceiverID', bulkData.receiverID),
    buildElement('TransactionDate', bulkData.transactionDate),
    buildElement('RecordCount', bulkData.claims.length.toString()),
    buildElement('DispositionFlag', bulkData.dispositionFlag),
  ]);

  // Build claim elements
  final claimElements = <XmlElement>[];
  for (final claimData in bulkData.claims) {
    claimElements.add(_buildClaimElement(claimData, buildElement));
  }

  final submission = XmlElement(
    XmlName('Claim.Submission'),
    [
      XmlAttribute(
          XmlName('xmlns:xsi'), 'http://www.w3.org/2001/XMLSchema-instance')
    ],
    [header, ...claimElements],
  );

  return XmlDocument([processingInstruction, submission])
      .toXmlString(pretty: true, indent: '  ');
}

/// Helper to build a single claim XML element
XmlElement _buildClaimElement(
    ClaimData data, XmlElement Function(String, String?) buildElement) {
  final Map<String, List<XmlElement>> claimChildren = {};

  void addChild(String tag, XmlElement element) {
    if (!claimChildren.containsKey(tag)) {
      claimChildren[tag] = [];
    }
    claimChildren[tag]!.add(element);
  }

  addChild('ID', buildElement('ID', data.claimId));
  if (data.idPayer != null) {
    addChild('IDPayer', buildElement('IDPayer', data.idPayer));
  }
  if (data.memberID != null) {
    addChild('MemberID', buildElement('MemberID', data.memberID));
  }
  addChild('PayerID', buildElement('PayerID', data.payerID));
  addChild('ProviderID', buildElement('ProviderID', data.providerID));
  if (data.weight != null) {
    addChild('Weight', buildElement('Weight', data.weight));
  }
  addChild('EmiratesIDNumber',
      buildElement('EmiratesIDNumber', data.emiratesIDNumber));
  addChild('Gross', buildElement('Gross', data.gross ?? '0'));
  addChild(
      'PatientShare', buildElement('PatientShare', data.patientShare ?? '0'));
  addChild('Net', buildElement('Net', data.net ?? '0'));

  final encounter = XmlElement(XmlName('Encounter'), [], [
    buildElement('FacilityID', data.facilityID),
    buildElement('Type', data.encounterType),
    buildElement('PatientID', data.patientId),
    buildElement('Start', data.start),
    if (data.end != null) buildElement('End', data.end),
    if (data.startType != null) buildElement('StartType', data.startType),
    if (data.endType != null) buildElement('EndType', data.endType),
    if (data.transferSource != null)
      buildElement('TransferSource', data.transferSource),
    if (data.transferDestination != null)
      buildElement('TransferDestination', data.transferDestination),
  ]);
  addChild('Encounter', encounter);

  for (final diagnosis in data.diagnoses) {
    addChild(
      'Diagnosis',
      XmlElement(XmlName('Diagnosis'), [], [
        buildElement('Type', diagnosis.type),
        buildElement('Code', diagnosis.code),
      ]),
    );
  }

  for (final activity in data.activities) {
    if (activity.isDeleted) continue;
    final activityChildren = [
      buildElement('ID', activity.id),
      buildElement('Start', activity.start),
      buildElement('Type', activity.type),
      buildElement('Code', activity.code),
      buildElement('Quantity', activity.quantity),
      buildElement('Net', activity.net),
      buildElement('Clinician', activity.clinician),
      if (activity.priorAuthorizationID != null)
        buildElement('PriorAuthorizationID', activity.priorAuthorizationID),
    ];
    for (final obs in activity.observations) {
      activityChildren.add(XmlElement(XmlName('Observation'), [], [
        buildElement('Type', obs.type),
        buildElement('Code', obs.code),
        if (obs.value.isNotEmpty) buildElement('Value', obs.value),
        if (obs.valueType.isNotEmpty) buildElement('ValueType', obs.valueType),
      ]));
    }
    addChild('Activity', XmlElement(XmlName('Activity'), [], activityChildren));
  }

  if (data.resubmission != null) {
    final resubmissionChildren = [
      buildElement('Type', data.resubmission!.type),
      buildElement('Comment', data.resubmission!.comment),
    ];
    if (data.resubmission!.attachment != null) {
      resubmissionChildren
          .add(buildElement('Attachment', data.resubmission!.attachment));
    }
    addChild('Resubmission',
        XmlElement(XmlName('Resubmission'), [], resubmissionChildren));
  }

  if (data.contract != null && data.contract!.packageName != null) {
    addChild(
      'Contract',
      XmlElement(XmlName('Contract'), [],
          [buildElement('PackageName', data.contract!.packageName)]),
    );
  }

  final List<XmlElement> orderedClaimChildren = [];
  for (final tag in claimChildOrder) {
    if (claimChildren.containsKey(tag)) {
      orderedClaimChildren.addAll(claimChildren[tag]!);
    }
  }

  return XmlElement(XmlName('Claim'), [], orderedClaimChildren);
}

class XmlHandler {
  // Deprecated: Use generateXmlString(data) instead for Isolate compatibility
  XmlDocument createXmlDocument(ClaimData data) {
    throw UnimplementedError("Use generateXmlString top-level function");
  }
}
