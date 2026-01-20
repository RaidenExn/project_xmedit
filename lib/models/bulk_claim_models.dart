import 'package:project_xmedit/models/claim_models.dart';

/// Lightweight representation of a claim for list display
class ClaimListItem {
  final String claimId;
  final String patientInfo;
  final String gross;
  final String net;
  final int index;
  final String size;

  ClaimListItem({
    required this.claimId,
    required this.patientInfo,
    required this.gross,
    required this.net,
    required this.index,
    required this.size,
  });

  /// Create list item from ClaimData
  factory ClaimListItem.fromClaimData(ClaimData claim, int index) {
    // Calculate size
    int bytes = 0;
    if (claim.rawXml != null) {
      bytes = claim.rawXml!.length;
    } else {
      // Fallback calculation (expensive but necessary if modified)
      // We don't want to run full generation here if possible, but
      // for accuracy we might need to, or just show 'Modified' or estimate.
      // For now, let's use a placeholder if null, or assume 0.
      // Actually, let's leave it 0 or '?' if unknown to avoid lag on big lists.
      // But wait! rawXml IS populated on load now.
      // If user edits, rawXml should be cleared.
      // Let's use 0 if unknown for now to stay fast.
      bytes = 0;
    }

    String formatBytes(int b) {
      if (b == 0) return '';
      if (b < 1024) return '$b B';
      if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
      return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return ClaimListItem(
      claimId: claim.claimId ?? 'UNKNOWN',
      patientInfo: claim.patientId ?? claim.emiratesIDNumber ?? 'N/A',
      gross: claim.gross ?? '0.00',
      net: claim.net ?? '0.00',
      index: index,
      size: formatBytes(bytes),
    );
  }
}

/// Wrapper for bulk XML data containing multiple claims
class BulkClaimData {
  // Shared header data across all claims
  String? senderID;
  String? receiverID;
  String? transactionDate;
  String? recordCount;
  String? dispositionFlag;

  // List of individual claims
  List<ClaimData> claims;

  // Original XML for reset functionality
  String? rawXml;

  // File path
  String? filePath;

  BulkClaimData({
    this.senderID,
    this.receiverID,
    this.transactionDate,
    this.recordCount,
    this.dispositionFlag,
    List<ClaimData>? claims,
    this.rawXml,
    this.filePath,
  }) : claims = claims ?? [];

  /// Deep clone for undo/reset functionality
  BulkClaimData clone() {
    return BulkClaimData(
      senderID: senderID,
      receiverID: receiverID,
      transactionDate: transactionDate,
      recordCount: recordCount,
      dispositionFlag: dispositionFlag,
      claims: claims.map((claim) => _cloneClaimData(claim)).toList(),
      rawXml: rawXml,
      filePath: filePath,
    );
  }

  /// Helper to deep clone ClaimData
  static ClaimData _cloneClaimData(ClaimData source) {
    final cloned = ClaimData()
      ..rawXml = source.rawXml
      ..senderID = source.senderID
      ..receiverID = source.receiverID
      ..transactionDate = source.transactionDate
      ..recordCount = source.recordCount
      ..dispositionFlag = source.dispositionFlag
      ..claimId = source.claimId
      ..idPayer = source.idPayer
      ..memberID = source.memberID
      ..payerID = source.payerID
      ..providerID = source.providerID
      ..weight = source.weight
      ..emiratesIDNumber = source.emiratesIDNumber
      ..gross = source.gross
      ..patientShare = source.patientShare
      ..net = source.net
      ..facilityID = source.facilityID
      ..encounterType = source.encounterType
      ..patientId = source.patientId
      ..start = source.start
      ..end = source.end
      ..startType = source.startType
      ..endType = source.endType
      ..transferSource = source.transferSource
      ..transferDestination = source.transferDestination;

    // Clone activities
    cloned.activities = source.activities
        .map((activity) => ActivityData.clone(activity))
        .toList();

    // Clone diagnoses
    cloned.diagnoses = source.diagnoses
        .map((diagnosis) => DiagnosisData.clone(diagnosis))
        .toList();

    // Clone resubmission if exists
    if (source.resubmission != null) {
      cloned.resubmission = ResubmissionData()
        ..type = source.resubmission!.type
        ..comment = source.resubmission!.comment
        ..attachment = source.resubmission!.attachment;
    }

    // Clone contract if exists
    if (source.contract != null) {
      cloned.contract = ContractData()
        ..packageName = source.contract!.packageName;
    }

    return cloned;
  }

  /// Get total number of claims
  int get totalClaims => claims.length;

  /// Estimate file size based on current claims
  /// Estimate file size based on current claims
  String getEstimatedFileSize() {
    int bytes;
    if (rawXml != null) {
      // If we have the raw XML (and it matches the data), use its length
      bytes = rawXml!.length;
    } else {
      // Fallback estimation:
      // Calculate average size from a sample if possible, or use heuristic
      // Let's assume average claim is around 2KB if small, or use a heuristic
      // Better heuristic: Convert a sample claim to string and multiply?
      // Too expensive. Let's stick to a safe heuristic but maybe smaller than 50KB?
      // Actually, if rawXml is null (edited), we might want to approximate better.
      // But for now, let's fix the "initial load" issue which is the main one.
      bytes = (claims.length * 5000) + 1024; // Lowered to 5KB default
    }

    return _formatBytes(bytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Generate list items for UI display
  List<ClaimListItem> getClaimListItems() {
    return claims
        .asMap()
        .entries
        .map((entry) => ClaimListItem.fromClaimData(entry.value, entry.key))
        .toList();
  }
}
