import 'package:flutter/foundation.dart';

/// Lightweight contract validator that performs deeper checks beyond
/// structural presence to help catch UI/runtime issues early.
///
/// This validator is non-fatal: it logs warnings in debug mode
/// and does not throw. It is intended to assist development and
/// analytics without blocking app operation.
class ContractValidator {
  void validate(Map<String, dynamic> contract) {
    try {
      _validateMeta(contract['meta']);
      _validatePagesUI(contract['pagesUI']);
      _validateTheming(contract['themingAccessibility']);
    } catch (e) {
      _log('Validator error: $e');
    }
  }

  void _validateMeta(dynamic meta) {
    if (meta is! Map) {
      _warn('meta must be an object');
      return;
    }
    if ((meta['version'] as String?)?.isEmpty ?? true) {
      _warn('meta.version is missing or empty');
    }
    if ((meta['appName'] as String?)?.isEmpty ?? true) {
      _warn('meta.appName is missing or empty');
    }
  }

  void _validatePagesUI(dynamic pagesUi) {
    if (pagesUi is! Map) {
      _warn('pagesUI must be an object');
      return;
    }
    final pages = pagesUi['pages'];
    if (pages is! Map) {
      _warn('pagesUI.pages must be an object');
    } else if (pages.isEmpty) {
      _warn('pagesUI.pages is empty — app may render blank');
    }
    final routes = pagesUi['routes'];
    if (routes is! Map) {
      _warn('pagesUI.routes must be an object');
    }
  }

  void _validateTheming(dynamic theming) {
    if (theming is! Map) return; // theming optional
    final tokens = (theming['tokens'] as Map?)?.cast<String, dynamic>();
    if (tokens == null || tokens.isEmpty) {
      _warn('themingAccessibility.tokens is missing or empty');
    }
    final typography = (theming['typography'] as Map?)?.cast<String, dynamic>();
    if (typography == null || typography.isEmpty) {
      _warn('themingAccessibility.typography is missing or empty');
    }
  }

  void _warn(String message) => _log('[validator] WARN $message');

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}