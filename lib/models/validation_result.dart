/// Severity levels for validation errors
enum ValidationSeverity { error, warning, info }

/// Represents a single validation error or warning
class ValidationError {
  final String field;
  final String message;
  final ValidationSeverity severity;
  final String? suggestion;

  const ValidationError({
    required this.field,
    required this.message,
    required this.severity,
    this.suggestion,
  });

  @override
  String toString() =>
      '[$field] $message${suggestion != null ? ' - $suggestion' : ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          message == other.message &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(field, message, severity);
}

/// Result of validation containing all errors and warnings
class ValidationResult {
  final List<ValidationError> errors;

  ValidationResult({required this.errors});

  /// True if there are no critical errors
  bool get isValid => criticalErrors.isEmpty;

  /// Get only critical errors
  List<ValidationError> get criticalErrors =>
      errors.where((e) => e.severity == ValidationSeverity.error).toList();

  /// Get only warnings
  List<ValidationError> get warnings =>
      errors.where((e) => e.severity == ValidationSeverity.warning).toList();

  /// Get only info messages
  List<ValidationError> get infos =>
      errors.where((e) => e.severity == ValidationSeverity.info).toList();

  /// Check if a specific field has errors
  bool hasErrorForField(String field) => errors
      .any((e) => e.field == field && e.severity == ValidationSeverity.error);

  /// Get errors for a specific field
  List<ValidationError> getErrorsForField(String field) =>
      errors.where((e) => e.field == field).toList();

  /// Get first error for a field (for inline display)
  ValidationError? getFirstErrorForField(String field) {
    final fieldErrors = getErrorsForField(field);
    return fieldErrors.isNotEmpty ? fieldErrors.first : null;
  }

  @override
  String toString() {
    if (isValid) return 'Validation passed';
    return 'Validation failed with ${criticalErrors.length} errors and ${warnings.length} warnings';
  }
}
