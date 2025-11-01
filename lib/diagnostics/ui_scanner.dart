import 'package:flutter/foundation.dart';

import '../models/config_models.dart';

/// UI Diagnostic Scanner
/// Scans the loaded CanonicalContract to identify rendering-related issues.
/// Checks include:
/// - Unrecognized component types
/// - Unresolved `${...}` bindings (theme/state)
/// - Missing page backgrounds
/// - Static lists/grids without explicit `pagination.enabled == false`
/// - Theme token references that don't resolve in `themingAccessibility.tokens`
class UIDiagnosticScanner {
  static const Set<String> _supportedTypes = {
    'text',
    'button',
    'textField',
    'card',
    'row',
    'column',
    'center',
    'list',
    'grid',
    'image',
    'icon',
    'chip',
    'progressIndicator',
    'searchBar',
    'form',
  };

  static UIDiagnosticReport scan(CanonicalContract contract) {
    final issues = <UIDiagnosticIssue>[];

    // Theming/token maps for validation
    final tokensByTheme = contract.themingAccessibility?.tokens ?? const {};
    final typography = contract.themingAccessibility?.typography ?? const {};

    // Helper: validate a single binding string like `${theme.primary}` or `${state.user.name}`
    void validateBinding({
      required String binding,
      required String pageId,
      String? componentId,
      String? componentType,
      String? propertyPath,
    }) {
      if (binding.isEmpty) return;
      if (!binding.contains(r'${')) return; // not a binding

      // Theme binding: ${theme.token}
      final themeMatch = RegExp(r"\$\{theme\.([a-zA-Z0-9_\-]+)\}")
          .firstMatch(binding);
      if (themeMatch != null) {
        final tokenName = themeMatch.group(1)!;
        final existsInAnyTheme = tokensByTheme.values
            .any((map) => map.containsKey(tokenName));
        if (!existsInAnyTheme) {
          issues.add(UIDiagnosticIssue(
            severity: DiagnosticSeverity.critical,
            category: 'ThemeToken',
            message: 'Theme token not found: `$tokenName`',
            pageId: pageId,
            componentId: componentId,
            componentType: componentType,
            propertyPath: propertyPath,
          ));
        }
        return;
      }

      // Typography binding: ${typography.heading1}
      final typoMatch = RegExp(r"\$\{typography\.([a-zA-Z0-9_\-]+)\}")
          .firstMatch(binding);
      if (typoMatch != null) {
        final typoName = typoMatch.group(1)!;
        final exists = typography.containsKey(typoName);
        if (!exists) {
          issues.add(UIDiagnosticIssue(
            severity: DiagnosticSeverity.warning,
            category: 'Typography',
            message: 'Typography token not found: `$typoName`',
            pageId: pageId,
            componentId: componentId,
            componentType: componentType,
            propertyPath: propertyPath,
          ));
        }
        return;
      }

      // State binding: ${state.key} or ${state.pageId.key}
      final stateMatch = RegExp(r"\$\{state\.([a-zA-Z0-9_\-\.]+)\}")
          .firstMatch(binding);
      if (stateMatch != null) {
        final rawPath = stateMatch.group(1)!; // e.g., 'user.name' or 'home.welcome'
        final parts = rawPath.split('.');
        if (parts.length == 1) {
          // global state key
          final key = parts.first;
          final exists = contract.state?.global.containsKey(key) ?? false;
          if (!exists) {
            issues.add(UIDiagnosticIssue(
              severity: DiagnosticSeverity.critical,
              category: 'StateBinding',
              message: 'Global state key missing: `$key`',
              pageId: pageId,
              componentId: componentId,
              componentType: componentType,
              propertyPath: propertyPath,
            ));
          }
        } else if (parts.length == 2) {
          final pageKey = parts[0];
          final fieldKey = parts[1];
          final pageState = contract.state?.pages[pageKey];
          final exists = pageState != null && pageState.containsKey(fieldKey);
          if (!exists) {
            issues.add(UIDiagnosticIssue(
              severity: DiagnosticSeverity.critical,
              category: 'StateBinding',
              message: 'Page state key missing: `${pageKey}.${fieldKey}`',
              pageId: pageId,
              componentId: componentId,
              componentType: componentType,
              propertyPath: propertyPath,
            ));
          }
        } else {
          // nested paths are not supported by the StateConfig schema
          issues.add(UIDiagnosticIssue(
            severity: DiagnosticSeverity.warning,
            category: 'StateBinding',
            message: 'Unsupported nested state path: `$rawPath`',
            pageId: pageId,
            componentId: componentId,
            componentType: componentType,
            propertyPath: propertyPath,
          ));
        }
        return;
      }

      // Unrecognized binding pattern
      issues.add(UIDiagnosticIssue(
        severity: DiagnosticSeverity.warning,
        category: 'Binding',
        message: 'Unrecognized binding pattern: `$binding`',
        pageId: pageId,
        componentId: componentId,
        componentType: componentType,
        propertyPath: propertyPath,
      ));
    }

    // Helper: collect and validate all bindings within component properties
    void validateComponentBindings(
      EnhancedComponentConfig component,
      String pageId,
    ) {
      String? id = component.id;
      String? type = component.type;

      // Validate type
      if (type == null || !_supportedTypes.contains(type)) {
        issues.add(UIDiagnosticIssue(
          severity: DiagnosticSeverity.warning,
          category: 'ComponentType',
          message: 'Unsupported or missing component type: `${type ?? 'unknown'}`',
          pageId: pageId,
          componentId: id,
          componentType: type,
        ));
      }

      // Common textual fields
      final candidates = <MapEntry<String, String?>>[
        MapEntry('text', component.text),
        MapEntry('label', component.label),
        MapEntry('placeholder', component.placeholder),
        MapEntry('binding', component.binding),
        MapEntry('src', component.src),
        MapEntry('style.color', component.style?.color),
        MapEntry('style.backgroundColor', component.style?.backgroundColor),
        MapEntry('style.foregroundColor', component.style?.foregroundColor),
        MapEntry('style.borderColor', component.style?.borderColor),
      ];

      for (final entry in candidates) {
        final value = entry.value;
        if (value == null) continue;
        if (value.contains(r'${')) {
          validateBinding(
            binding: value,
            pageId: pageId,
            componentId: id,
            componentType: type,
            propertyPath: entry.key,
          );
        }
      }

      // Lists/grids static pagination check
      if (type == 'list' || type == 'grid') {
        final ds = component.dataSource;
        final isStatic = ds == null ||
            ((ds.service == null || ds.service!.isEmpty) &&
             (ds.endpoint == null || ds.endpoint!.isEmpty));

        final paginationEnabled = ds?.pagination?.enabled;
        final hasExplicitPaginationFalse = paginationEnabled == false;

        if (isStatic && !hasExplicitPaginationFalse) {
          issues.add(UIDiagnosticIssue(
            severity: DiagnosticSeverity.warning,
            category: 'Pagination',
            message: 'Static ${type} lacks `pagination.enabled: false`',
            pageId: pageId,
            componentId: id,
            componentType: type,
          ));
        }
      }

      // children recursion
      final children = component.children ?? const [];
      for (final child in children) {
        validateComponentBindings(child, pageId);
      }
    }

    // Traverse pages
    final pages = contract.pagesUI?.pages ?? const {};
    pages.forEach((pageId, page) {
      // Page background check
      final bg = page.style?.backgroundColor;
      if (bg == null || bg.isEmpty) {
        issues.add(UIDiagnosticIssue(
          severity: DiagnosticSeverity.warning,
          category: 'PageBackground',
          message: 'Page has no backgroundColor in style',
          pageId: pageId,
        ));
      } else if (bg.contains(r'${')) {
        validateBinding(
          binding: bg,
          pageId: pageId,
          componentType: 'page',
          propertyPath: 'page.style.backgroundColor',
        );
      }

      // Components (use EnhancedPageConfig.children)
      for (final component in page.children ?? const []) {
        validateComponentBindings(component, pageId);
      }
    });

    return UIDiagnosticReport(issues: issues);
  }

  static void printReport(UIDiagnosticReport report) {
    final buffer = StringBuffer();
    buffer.writeln('=== UI Diagnostic Scanner Report ===');
    buffer.writeln('Total issues: ${report.issues.length}');

    final grouped = <String, List<UIDiagnosticIssue>>{};
    for (final issue in report.issues) {
      grouped.putIfAbsent(issue.category, () => []).add(issue);
    }

    for (final entry in grouped.entries) {
      buffer.writeln('\n[Category: ${entry.key}] Count: ${entry.value.length}');
      for (final issue in entry.value) {
        buffer.writeln('- ${describeEnum(issue.severity).toUpperCase()} | page=${issue.pageId ?? '-'} | type=${issue.componentType ?? '-'} | id=${issue.componentId ?? '-'}');
        buffer.writeln('  ${issue.message}');
        if (issue.propertyPath != null) {
          buffer.writeln('  at: ${issue.propertyPath}');
        }
      }
    }

    debugPrint(buffer.toString());
  }
}

class UIDiagnosticReport {
  final List<UIDiagnosticIssue> issues;
  UIDiagnosticReport({required this.issues});

  int get criticalCount =>
      issues.where((i) => i.severity == DiagnosticSeverity.critical).length;
  int get warningCount =>
      issues.where((i) => i.severity == DiagnosticSeverity.warning).length;
}

enum DiagnosticSeverity { critical, warning }

class UIDiagnosticIssue {
  final DiagnosticSeverity severity;
  final String category; // ThemeToken | StateBinding | ComponentType | PageBackground | Pagination | Typography | Binding
  final String message;
  final String? pageId;
  final String? componentId;
  final String? componentType;
  final String? propertyPath;

  UIDiagnosticIssue({
    required this.severity,
    required this.category,
    required this.message,
    this.pageId,
    this.componentId,
    this.componentType,
    this.propertyPath,
  });
}