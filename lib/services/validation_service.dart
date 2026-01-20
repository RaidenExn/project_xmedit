import 'package:project_xmedit/models/claim_models.dart';

/// Validation error model
class ValidationError {
  final String field;
  final String message;

  ValidationError(this.field, this.message);

  @override
  String toString() => '$field: $message';
}

/// Validation service for claim data
class ValidationService {
  /// Validate claim data
  static List<ValidationError> validateClaim(ClaimData claim) {
    final errors = <ValidationError>[];

    // Required fields
    if (claim.claimId == null || claim.claimId!.isEmpty) {
      errors.add(ValidationError('Claim ID', 'Claim ID is required'));
    }

    if (claim.payerID == null || claim.payerID!.isEmpty) {
      errors.add(ValidationError('Payer ID', 'Payer ID is required'));
    }

    if (claim.providerID == null || claim.providerID!.isEmpty) {
      errors.add(ValidationError('Provider ID', 'Provider ID is required'));
    }

    // Financial validation
    final gross = double.tryParse(claim.gross ?? '0');
    final patientShare = double.tryParse(claim.patientShare ?? '0');
    final net = double.tryParse(claim.net ?? '0');

    if (gross == null) {
      errors.add(ValidationError('Gross Amount', 'Invalid gross amount'));
    } else if (gross < 0) {
      errors.add(
          ValidationError('Gross Amount', 'Gross amount cannot be negative'));
    }

    if (patientShare == null) {
      errors.add(
          ValidationError('Patient Share', 'Invalid patient share amount'));
    } else if (patientShare < 0) {
      errors.add(
          ValidationError('Patient Share', 'Patient share cannot be negative'));
    }

    if (net == null) {
      errors.add(ValidationError('Net Amount', 'Invalid net amount'));
    } else if (net < 0) {
      errors
          .add(ValidationError('Net Amount', 'Net amount cannot be negative'));
    }

    // Balance check: Gross = Net + PatientShare
    if (gross != null && patientShare != null && net != null) {
      final calculatedNet = gross - patientShare;
      if ((calculatedNet - net).abs() > 0.01) {
        errors.add(
          ValidationError(
            'Financial Balance',
            'Gross (${gross.toStringAsFixed(2)}) should equal Net (${net.toStringAsFixed(2)}) + Patient Share (${patientShare.toStringAsFixed(2)})',
          ),
        );
      }
    }

    // Activities validation
    if (claim.activities.isEmpty) {
      errors.add(
          ValidationError('Activities', 'At least one activity is required'));
    }

    for (var i = 0; i < claim.activities.length; i++) {
      final activity = claim.activities[i];
      if (activity.code == null || activity.code!.isEmpty) {
        errors.add(
            ValidationError('Activity ${i + 1}', 'Activity code is required'));
      }
      if (activity.net == null || double.tryParse(activity.net!) == null) {
        errors.add(ValidationError(
            'Activity ${i + 1}', 'Valid net amount is required'));
      }
    }

    // Diagnoses validation
    if (claim.diagnoses.isEmpty) {
      errors.add(
          ValidationError('Diagnoses', 'At least one diagnosis is required'));
    }

    var hasPrincipal = false;
    for (var i = 0; i < claim.diagnoses.length; i++) {
      final diagnosis = claim.diagnoses[i];
      if (diagnosis.type == 'Principal') {
        hasPrincipal = true;
      }
      if (diagnosis.code == null || diagnosis.code!.isEmpty) {
        errors.add(ValidationError(
            'Diagnosis ${i + 1}', 'Diagnosis code is required'));
      }
    }

    if (!hasPrincipal && claim.diagnoses.isNotEmpty) {
      errors.add(ValidationError(
          'Diagnoses', 'At least one principal diagnosis is required'));
    }

    // Encounter validation
    if (claim.start == null || claim.start!.isEmpty) {
      errors.add(ValidationError('Encounter', 'Start date/time is required'));
    }

    if (claim.end == null || claim.end!.isEmpty) {
      errors.add(ValidationError('Encounter', 'End date/time is required'));
    }

    return errors;
  }

  /// Quick validation - just check critical fields
  static bool isValidForSaving(ClaimData claim) {
    return claim.claimId != null &&
        claim.claimId!.isNotEmpty &&
        claim.gross != null &&
        double.tryParse(claim.gross!) != null;
  }

  /// Validate Emirates ID format
  static bool isValidEmiratesID(String? emiratesID) {
    if (emiratesID == null || emiratesID.isEmpty) return true; // Optional field
    // Format: 784-YYYY-NNNNNNN-N
    final pattern = RegExp(r'^784-\d{4}-\d{7}-\d{1}$');
    return pattern.hasMatch(emiratesID);
  }
}
