// Validation result models for contract validation.
//
// Provides structured errors, warnings, and summary statistics.

class ValidationResult {
  // Provides structured errors, warnings, and summary statistics for a contract.
  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;
  final ValidationStats stats;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.stats,
  });
}

class ValidationError {
  // Represents a single validation error with path and message.
  final String path;
  final String message;

  ValidationError({required this.path, required this.message});

  @override
  String toString() => '[ERROR] $path: $message';
}

class ValidationWarning {
  // Represents a single validation warning with path and message.
  final String path;
  final String message;

  ValidationWarning({required this.path, required this.message});

  @override
  String toString() => '[WARN] $path: $message';
}

class ValidationStats {
  // Summary counts for components, actions, and pages.
  int components;
  int actions;
  int pages;

  ValidationStats({this.components = 0, this.actions = 0, this.pages = 0});
}
