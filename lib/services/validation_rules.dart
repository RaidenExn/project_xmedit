import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/models/validation_result.dart';

/// DHPO-specific validation rules for medical claim XML files
class ValidationRules {
  /// Validate claim ID is present and not empty
  static ValidationError? validateClaimId(String? claimId) {
    if (claimId == null || claimId.trim().isEmpty) {
      return const ValidationError(
        field: 'claimId',
        message: 'Claim ID is required',
        severity: ValidationSeverity.error,
        suggestion: 'Enter a valid claim identifier',
      );
    }
    return null;
  }

  /// Validate ICD-10 diagnosis code format
  /// Format: Letter + 2-3 digits + optional decimal + 1-4 characters
  static ValidationError? validateIcd10Code(String? code) {
    if (code == null || code.trim().isEmpty) {
      return const ValidationError(
        field: 'diagnosisCode',
        message: 'Diagnosis code cannot be empty',
        severity: ValidationSeverity.error,
      );
    }

    final cleanCode = code.trim().toUpperCase();

    // ICD-10 pattern: Letter + 2-3 digits + optional (. + 1-4 chars)
    final icd10Pattern = RegExp(r'^[A-Z]\d{2,3}(\.\d{1,4})?$');

    if (!icd10Pattern.hasMatch(cleanCode)) {
      return const ValidationError(
        field: 'diagnosisCode',
        message: 'Invalid ICD-10 code format',
        severity: ValidationSeverity.error,
        suggestion: 'Format should be like A00 or A00.1234',
      );
    }

    return null;
  }

  /// Validate date format (YYYY-MM-DD)
  static ValidationError? validateDate(String? dateStr, String fieldName) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      return null; // Empty dates are allowed for optional fields
    }

    // Check format YYYY-MM-DD
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (!datePattern.hasMatch(dateStr)) {
      return ValidationError(
        field: fieldName,
        message: 'Invalid date format',
        severity: ValidationSeverity.error,
        suggestion: 'Use YYYY-MM-DD format (e.g., 2024-01-20)',
      );
    }

    // Try to parse the date
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();

      // Warn if date is in the future
      if (date.isAfter(now.add(const Duration(days: 1)))) {
        return ValidationError(
          field: fieldName,
          message: 'Date is in the future',
          severity: ValidationSeverity.warning,
          suggestion: 'Verify this date is correct',
        );
      }

      // Warn if date is very old (more than 5 years ago)
      if (date.isBefore(now.subtract(const Duration(days: 365 * 5)))) {
        return ValidationError(
          field: fieldName,
          message: 'Date is more than 5 years old',
          severity: ValidationSeverity.info,
          suggestion: 'Verify this date is correct',
        );
      }
    } catch (e) {
      return ValidationError(
        field: fieldName,
        message: 'Invalid date',
        severity: ValidationSeverity.error,
        suggestion: 'Date must be a valid calendar date',
      );
    }

    return null;
  }

  /// Validate totals matching: Gross = Net + Patient Share
  static ValidationError? validateTotals(ClaimData claim) {
    final gross = double.tryParse(claim.gross ?? '0') ?? 0.0;
    final net = double.tryParse(claim.net ?? '0') ?? 0.0;
    final patientShare = double.tryParse(claim.patientShare ?? '0') ?? 0.0;

    final expectedGross = net + patientShare;
    final difference = (gross - expectedGross).abs();

    // Allow 1 cent tolerance for rounding
    if (difference > 0.01) {
      return ValidationError(
        field: 'totals',
        message:
            'Gross (${gross.toStringAsFixed(2)}) ≠ Net (${net.toStringAsFixed(2)}) + Patient Share (${patientShare.toStringAsFixed(2)})',
        severity: ValidationSeverity.error,
        suggestion: 'Gross amount should equal Net + Patient Share',
      );
    }

    return null;
  }

  /// Validate activity sum matches claim net
  static ValidationError? validateActivitySum(ClaimData claim) {
    final activities = claim.activities.where((a) => !a.isDeleted).toList();

    if (activities.isEmpty) {
      return const ValidationError(
        field: 'activities',
        message: 'No activities found',
        severity: ValidationSeverity.warning,
        suggestion: 'Add at least one activity',
      );
    }

    final activitySum = activities.fold<double>(
      0.0,
      (sum, activity) => sum + (double.tryParse(activity.net ?? '0') ?? 0.0),
    );

    final claimNet = double.tryParse(claim.net ?? '0') ?? 0.0;
    final difference = (activitySum - claimNet).abs();

    // Allow 1 cent tolerance
    if (difference > 0.01) {
      return ValidationError(
        field: 'activities',
        message:
            'Activity sum (${activitySum.toStringAsFixed(2)}) ≠ Claim net (${claimNet.toStringAsFixed(2)})',
        severity: ValidationSeverity.warning,
        suggestion: 'Activity totals should match claim net amount',
      );
    }

    return null;
  }

  /// Validate at least one principal diagnosis exists
  static ValidationError? validatePrincipalDiagnosis(ClaimData claim) {
    final hasPrincipal =
        claim.diagnoses.any((d) => d.type?.toLowerCase() == 'principal');

    if (!hasPrincipal && claim.diagnoses.isNotEmpty) {
      return const ValidationError(
        field: 'diagnoses',
        message: 'No principal diagnosis found',
        severity: ValidationSeverity.warning,
        suggestion: 'Mark one diagnosis as principal',
      );
    }

    if (claim.diagnoses.isEmpty) {
      return const ValidationError(
        field: 'diagnoses',
        message: 'No diagnoses found',
        severity: ValidationSeverity.warning,
        suggestion: 'Add at least one diagnosis',
      );
    }

    return null;
  }

  /// Validate patient information is complete
  static List<ValidationError> validatePatientInfo(ClaimData claim) {
    final errors = <ValidationError>[];

    if (claim.patientId == null || claim.patientId!.trim().isEmpty) {
      errors.add(const ValidationError(
        field: 'patientId',
        message: 'Patient ID is required',
        severity: ValidationSeverity.error,
      ));
    }

    if (claim.memberID == null || claim.memberID!.trim().isEmpty) {
      errors.add(const ValidationError(
        field: 'memberID',
        message: 'Member ID is required',
        severity: ValidationSeverity.error,
      ));
    }

    return errors;
  }

  /// Validate payer information is complete
  static List<ValidationError> validatePayerInfo(ClaimData claim) {
    final errors = <ValidationError>[];

    if (claim.payerID == null || claim.payerID!.trim().isEmpty) {
      errors.add(const ValidationError(
        field: 'payerID',
        message: 'Payer ID is required',
        severity: ValidationSeverity.error,
      ));
    }

    return errors;
  }

  /// Validate activity has required fields
  static ValidationError? validateActivity(ActivityData activity, int index) {
    if (activity.code == null || activity.code!.trim().isEmpty) {
      return ValidationError(
        field: 'activity_${index}_code',
        message: 'Activity $index has no code',
        severity: ValidationSeverity.error,
        suggestion: 'Enter a valid CPT code',
      );
    }

    final net = double.tryParse(activity.net ?? '0');
    if (net == null || net < 0) {
      return ValidationError(
        field: 'activity_${index}_net',
        message: 'Activity $index has invalid net amount',
        severity: ValidationSeverity.error,
        suggestion: 'Net amount must be a positive number',
      );
    }

    final quantity = int.tryParse(activity.quantity ?? '0');
    if (quantity == null || quantity < 1) {
      return ValidationError(
        field: 'activity_${index}_quantity',
        message: 'Activity $index has invalid quantity',
        severity: ValidationSeverity.warning,
        suggestion: 'Quantity should be at least 1',
      );
    }

    return null;
  }

  /// Validate resubmission information if applicable
  static List<ValidationError> validateResubmission(ClaimData claim) {
    final errors = <ValidationError>[];

    if (claim.resubmission != null &&
        claim.resubmission!.type != null &&
        claim.resubmission!.type!.isNotEmpty) {
      if (claim.resubmission!.comment == null ||
          claim.resubmission!.comment!.trim().isEmpty) {
        errors.add(const ValidationError(
          field: 'resubmissionComment',
          message: 'Resubmission comment is required when type is set',
          severity: ValidationSeverity.warning,
          suggestion: 'Provide a reason for resubmission',
        ));
      }
    }

    return errors;
  }

  /// Validate amount is a valid positive number
  static ValidationError? validateAmount(String? amount, String fieldName) {
    if (amount == null || amount.trim().isEmpty) {
      return ValidationError(
        field: fieldName,
        message: '$fieldName is required',
        severity: ValidationSeverity.error,
      );
    }

    final value = double.tryParse(amount);
    if (value == null) {
      return ValidationError(
        field: fieldName,
        message: '$fieldName must be a valid number',
        severity: ValidationSeverity.error,
        suggestion: 'Enter a numeric value (e.g., 100.50)',
      );
    }

    if (value < 0) {
      return ValidationError(
        field: fieldName,
        message: '$fieldName cannot be negative',
        severity: ValidationSeverity.error,
      );
    }

    return null;
  }
}
