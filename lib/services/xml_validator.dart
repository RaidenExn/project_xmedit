import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/models/validation_result.dart';
import 'package:project_xmedit/services/validation_rules.dart';

/// Core XML validator for claim data
/// Orchestrates all validation rules and returns comprehensive results
class XmlValidator {
  /// Validate an entire claim
  static ValidationResult validateClaim(ClaimData claim) {
    final errors = <ValidationError>[];

    // 1. Validate claim ID (required)
    final claimIdError = ValidationRules.validateClaimId(claim.claimId);
    if (claimIdError != null) errors.add(claimIdError);

    // 2. Validate patient information
    errors.addAll(ValidationRules.validatePatientInfo(claim));

    // 3. Validate payer information
    errors.addAll(ValidationRules.validatePayerInfo(claim));

    // 4. Validate dates (encounter start/end)
    final startDateError =
        ValidationRules.validateDate(claim.start, 'encounterStart');
    if (startDateError != null) errors.add(startDateError);

    final endDateError =
        ValidationRules.validateDate(claim.end, 'encounterEnd');
    if (endDateError != null) errors.add(endDateError);

    // 5. Validate amounts
    final grossError = ValidationRules.validateAmount(claim.gross, 'gross');
    if (grossError != null) errors.add(grossError);

    final netError = ValidationRules.validateAmount(claim.net, 'net');
    if (netError != null) errors.add(netError);

    final patientShareError =
        ValidationRules.validateAmount(claim.patientShare, 'patientShare');
    if (patientShareError != null) errors.add(patientShareError);

    // 6. Validate totals matching
    final totalsError = ValidationRules.validateTotals(claim);
    if (totalsError != null) errors.add(totalsError);

    // 7. Validate activities
    final activitySumError = ValidationRules.validateActivitySum(claim);
    if (activitySumError != null) errors.add(activitySumError);

    // Validate each activity
    for (var i = 0; i < claim.activities.length; i++) {
      if (!claim.activities[i].isDeleted) {
        final activityError =
            ValidationRules.validateActivity(claim.activities[i], i + 1);
        if (activityError != null) errors.add(activityError);
      }
    }

    // 8. Validate diagnoses
    final diagnosisError = ValidationRules.validatePrincipalDiagnosis(claim);
    if (diagnosisError != null) errors.add(diagnosisError);

    // Validate each diagnosis code format
    for (var i = 0; i < claim.diagnoses.length; i++) {
      final diagnosis = claim.diagnoses[i];
      final codeError = ValidationRules.validateIcd10Code(diagnosis.code);
      if (codeError != null) {
        errors.add(ValidationError(
          field: 'diagnosis_${i + 1}_code',
          message: codeError.message,
          severity: codeError.severity,
          suggestion: codeError.suggestion,
        ));
      }
    }

    // 9. Validate resubmission information
    errors.addAll(ValidationRules.validateResubmission(claim));

    return ValidationResult(errors: errors);
  }

  /// Quick validation for specific field (for inline validation)
  static ValidationError? validateField(
      String fieldName, dynamic value, ClaimData? claim) {
    switch (fieldName) {
      case 'claimId':
        return ValidationRules.validateClaimId(value as String?);

      case 'encounterStart':
      case 'encounterEnd':
      case 'start':
      case 'end':
        return ValidationRules.validateDate(value as String?, fieldName);

      case 'gross':
      case 'net':
      case 'patientShare':
        return ValidationRules.validateAmount(value as String?, fieldName);

      case 'diagnosisCode':
        return ValidationRules.validateIcd10Code(value as String?);

      case 'patientId':
        if (value == null || (value as String).trim().isEmpty) {
          return const ValidationError(
            field: 'patientId',
            message: 'Patient ID is required',
            severity: ValidationSeverity.error,
          );
        }
        return null;

      case 'memberID':
        if (value == null || (value as String).trim().isEmpty) {
          return const ValidationError(
            field: 'memberID',
            message: 'Member ID is required',
            severity: ValidationSeverity.error,
          );
        }
        return null;

      case 'payerID':
        if (value == null || (value as String).trim().isEmpty) {
          return const ValidationError(
            field: 'payerID',
            message: 'Payer ID is required',
            severity: ValidationSeverity.error,
          );
        }
        return null;
    }

    return null;
  }

  /// Validate before save - returns true if safe to save
  static bool canSave(ClaimData claim) {
    final result = validateClaim(claim);
    return result.criticalErrors.isEmpty;
  }

  /// Get validation summary string
  static String getValidationSummary(ValidationResult result) {
    if (result.isValid) {
      if (result.warnings.isEmpty && result.infos.isEmpty) {
        return 'No issues found';
      }
      return '${result.warnings.length} warnings';
    }

    final errorCount = result.criticalErrors.length;
    final warningCount = result.warnings.length;

    final parts = <String>[];
    if (errorCount > 0) {
      parts.add('$errorCount ${errorCount == 1 ? 'error' : 'errors'}');
    }
    if (warningCount > 0) {
      parts.add('$warningCount ${warningCount == 1 ? 'warning' : 'warnings'}');
    }

    return parts.join(', ');
  }
}
