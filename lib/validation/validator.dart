import '../models/config_models.dart';

/// Enhanced validator with rule-based validation
class EnhancedValidator {
  ValidationsConfig? _config;

  /// Initialize with validations configuration
  void initialize(ValidationsConfig config) {
    _config = config;
  }

  /// Validate a single field
  ValidationResult validateField(
    String fieldName,
    dynamic value,
    ValidationConfig config,
  ) {
    // Required validation
    if (config.required == true &&
        (value == null || value.toString().trim().isEmpty)) {
      return ValidationResult(
        isValid: false,
        message: config.message ?? 'This field is required',
      );
    }

    // Skip other validations if value is empty and not required
    if (value == null || value.toString().trim().isEmpty) {
      return ValidationResult(isValid: true);
    }

    final stringValue = value.toString();

    // Email validation
    if (config.email == true) {
      if (!_isValidEmail(stringValue)) {
        return ValidationResult(
          isValid: false,
          message: config.message ?? 'Please enter a valid email address',
        );
      }
    }

    // Length validations
    if (config.minLength != null && stringValue.length < config.minLength!) {
      return ValidationResult(
        isValid: false,
        message:
            config.message ?? 'Must be at least ${config.minLength} characters',
      );
    }

    if (config.maxLength != null && stringValue.length > config.maxLength!) {
      return ValidationResult(
        isValid: false,
        message:
            config.message ?? 'Must be at most ${config.maxLength} characters',
      );
    }

    // Pattern validation
    if (config.pattern != null) {
      final regex = RegExp(config.pattern!);
      if (!regex.hasMatch(stringValue)) {
        return ValidationResult(
          isValid: false,
          message: config.message ?? 'Invalid format',
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  /// Validate using predefined rules
  ValidationResult validateWithRule(String ruleName, dynamic value) {
    if (_config == null) {
      return ValidationResult(isValid: true);
    }

    final rule = _config!.rules[ruleName];
    if (rule == null) {
      return ValidationResult(isValid: true);
    }

    // Required validation
    if (rule.notEmpty == true &&
        (value == null || value.toString().trim().isEmpty)) {
      return ValidationResult(isValid: false, message: rule.message);
    }

    // Skip other validations if value is empty
    if (value == null || value.toString().trim().isEmpty) {
      return ValidationResult(isValid: true);
    }

    final stringValue = value.toString();

    // Length validation
    if (rule.minLength != null && stringValue.length < rule.minLength!) {
      return ValidationResult(isValid: false, message: rule.message);
    }

    // Pattern validation
    if (rule.pattern != null) {
      final regex = RegExp(rule.pattern!);
      if (!regex.hasMatch(stringValue)) {
        return ValidationResult(isValid: false, message: rule.message);
      }
    }

    return ValidationResult(isValid: true);
  }

  /// Validate cross-field rules
  ValidationResult validateCrossField(
    String ruleName,
    Map<String, dynamic> formData,
  ) {
    if (_config == null) {
      return ValidationResult(isValid: true);
    }

    final rule = _config!.crossField[ruleName];
    if (rule == null) {
      return ValidationResult(isValid: true);
    }

    switch (rule.rule) {
      case 'equal':
        if (rule.fields.length >= 2) {
          final value1 = formData[rule.fields[0]];
          final value2 = formData[rule.fields[1]];
          if (value1 != value2) {
            return ValidationResult(isValid: false, message: rule.message);
          }
        }
        break;
      default:
        break;
    }

    return ValidationResult(isValid: true);
  }

  /// Validate entire form
  Map<String, ValidationResult> validateForm(
    Map<String, ValidationConfig> fieldConfigs,
    Map<String, dynamic> formData,
  ) {
    final results = <String, ValidationResult>{};

    for (final entry in fieldConfigs.entries) {
      final fieldName = entry.key;
      final config = entry.value;
      final value = formData[fieldName];

      results[fieldName] = validateField(fieldName, value, config);
    }

    return results;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }
}

/// Validation result model
class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult({required this.isValid, this.message});
}
