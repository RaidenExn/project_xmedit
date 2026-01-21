// UI Constants for the application
// Extracted to improve maintainability and consistency

/// Minimum table width for activities and other data tables
const double kMinTableWidth = 800.0;

/// Spacing between major sections
const double kSectionSpacing = 16.0;

/// Maximum undo stack size for bulk operations
const int kMaxUndoStackSize = 10;

/// Maximum file size for bulk XML split operations (in bytes)
const int kMaxBulkFileSizeBytes = 2950 * 1024; // ~2.95 MB

/// Activity type codes
class ActivityTypes {
  static const String cpt = '3';
  static const String dsl = '8';
  static const String drug = '5';
  static const String cdt = '6';

  static const Set<String> knownTypes = {cpt, dsl, drug, cdt};
}

/// Activity type display names
class ActivityTypeNames {
  static const String cpt = 'CPT';
  static const String dsl = 'DSL';
  static const String drug = 'Drug';
  static const String cdt = 'CDT';
  static const String unknown = 'Other/Unknown';
}
