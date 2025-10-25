import 'dart:io';

import 'validation_result.dart';

/// Validates canonical JSON contracts against supported features extracted from docs.
///
/// Checks components, actions, services schemas, state configuration, and cross-references
/// (routes, endpoints, icons, bindings), returning structured errors/warnings and basic stats.
class ContractValidator {
  // Fallback constants; doc-derived lists override when available.
  static const List<String> supportedStateScopes = [
    'global',
    'page',
    'session',
    'memory',
  ];
  static const List<String> supportedPersistence = [
    'local',
    'secure',
    'session',
    'memory',
  ];

  static List<String> get supportedComponents =>
      _DocFeatures.instance.components.isNotEmpty
          ? _DocFeatures.instance.components
          : [
            'text',
            'textField',
            'text_field',
            'button',
            'textButton',
            'iconButton',
            'icon',
            'image',
            'card',
            'list',
            'grid',
            'row',
            'column',
            'center',
            'hero',
            'form',
            'searchBar',
            'filterChips',
            'chip',
            'progressIndicator',
            'switch',
            'slider',
            'audio',
            'video',
            'webview',
          ];

  static List<String> get supportedActions =>
      _DocFeatures.instance.actions.isNotEmpty
          ? _DocFeatures.instance.actions
          : [
            'navigate',
            'pop',
            'openUrl',
            'apiCall',
            'updateState',
            'showError',
            'showSuccess',
            'submitForm',
            'refreshData',
            'showBottomSheet',
            'showDialog',
            'clearCache',
            'undo',
            'redo',
          ];

  static List<String> get supportedValidations =>
      _DocFeatures.instance.validations.isNotEmpty
          ? _DocFeatures.instance.validations
          : [
            'required',
            'email',
            'minLength',
            'maxLength',
            'pattern',
            'message',
            'equal',
          ];

  /// Backward-compatible static entry that returns error messages.
  static List<String> validate(Map<String, dynamic> contract) {
    final result = ContractValidator().validateContract(contract);
    return result.errors.map((e) => '${e.path}: ${e.message}').toList();
  }

  /// Main entry point.
  ValidationResult validateContract(Map<String, dynamic> contract) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final stats = ValidationStats();

    // Required sections
    if (contract['meta'] is! Map) {
      errors.add(
        ValidationError(
          path: 'meta',
          message: 'Required section missing or invalid',
        ),
      );
    }
    if (contract['pagesUI'] is! Map) {
      errors.add(
        ValidationError(
          path: 'pagesUI',
          message: 'Required section missing or invalid',
        ),
      );
    }

    // Components/pages
    final pagesUi = contract['pagesUI'] as Map<String, dynamic>?;
    if (pagesUi != null) {
      final pages = (pagesUi['pages'] ?? {}) as Map<String, dynamic>;
      stats.pages = pages.length;
      for (final entry in pages.entries) {
        _validatePage(
          entry.key,
          entry.value as Map<String, dynamic>,
          errors,
          warnings,
          stats,
          contract,
        );
      }
      // routes cross-refs
      _validateRoutes(pagesUi, errors, warnings);
    }

    // Actions top-level (eventsActions)
    if (contract['eventsActions'] is Map<String, dynamic>) {
      _validateTopLevelActions(
        contract['eventsActions'] as Map<String, dynamic>,
        errors,
        warnings,
        stats,
        contract,
      );
    }

    // Services
    if (contract['services'] is Map<String, dynamic>) {
      _validateServices(contract, errors, warnings);
    }

    // State
    if (contract['state'] is Map<String, dynamic>) {
      _validateState(
        contract['state'] as Map<String, dynamic>,
        errors,
        warnings,
      );
    }

    // Cross references (icons, service endpoints in actions)
    _validateCrossReferences(contract, errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      stats: stats,
    );
  }

  void _validatePage(
    String pageId,
    Map<String, dynamic> page,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
    ValidationStats stats,
    Map<String, dynamic> contract,
  ) {
    final children = (page['children'] ?? []) as List<dynamic>;
    for (var i = 0; i < children.length; i++) {
      final comp = children[i];
      _validateComponent(
        'pagesUI.pages.$pageId.children[$i]',
        comp,
        errors,
        warnings,
        stats,
        contract,
      );
    }
  }

  void _validateComponent(
    String path,
    dynamic comp,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
    ValidationStats stats,
    Map<String, dynamic> contract,
  ) {
    if (comp is! Map<String, dynamic>) {
      errors.add(
        ValidationError(path: path, message: 'Component must be an object'),
      );
      return;
    }
    stats.components++;

    final type = comp['type']?.toString();
    if (type == null || !supportedComponents.contains(type)) {
      errors.add(
        ValidationError(
          path: '$path.type',
          message: 'Unsupported component type: $type',
        ),
      );
    }

    // Validate bindings
    if (comp.containsKey('binding')) {
      final binding = comp['binding']?.toString() ?? '';
      if (_isStateBinding(binding)) {
        // ok
      } else if (_isItemBinding(binding) || _looksLikeItemField(binding)) {
        // ok
      } else {
        warnings.add(
          ValidationWarning(
            path: '$path.binding',
            message: 'Binding format not recognized',
          ),
        );
      }
    }

    // Validate inline validation rules
    if (comp['validation'] is Map<String, dynamic>) {
      final v = comp['validation'] as Map<String, dynamic>;
      for (final key in v.keys) {
        if (!supportedValidations.contains(key)) {
          warnings.add(
            ValidationWarning(
              path: '$path.validation.$key',
              message: 'Unknown validation rule',
            ),
          );
        }
      }
    }

    // Actions on component
    for (final actionKey in ['onTap', 'onChanged', 'onSubmit']) {
      if (comp[actionKey] is Map<String, dynamic>) {
        _validateAction(
          '$path.$actionKey',
          comp[actionKey] as Map<String, dynamic>,
          errors,
          warnings,
          stats,
          contract,
        );
      }
    }

    // Recurse children
    if (comp['children'] is List) {
      final children = comp['children'] as List<dynamic>;
      for (var i = 0; i < children.length; i++) {
        _validateComponent(
          '$path.children[$i]',
          children[i],
          errors,
          warnings,
          stats,
          contract,
        );
      }
    }

    // List itemBuilder
    if (comp['itemBuilder'] is Map<String, dynamic>) {
      _validateComponent(
        '$path.itemBuilder',
        comp['itemBuilder'],
        errors,
        warnings,
        stats,
        contract,
      );
    }
  }

  void _validateTopLevelActions(
    Map<String, dynamic> eventsActions,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
    ValidationStats stats,
    Map<String, dynamic> contract,
  ) {
    for (final entry in eventsActions.entries) {
      final arr = entry.value;
      if (arr is List<dynamic>) {
        for (var i = 0; i < arr.length; i++) {
          final act = arr[i];
          if (act is Map<String, dynamic>) {
            _validateAction(
              'eventsActions.${entry.key}[$i]',
              act,
              errors,
              warnings,
              stats,
              contract,
            );
          } else {
            errors.add(
              ValidationError(
                path: 'eventsActions.${entry.key}[$i]',
                message: 'Action must be an object',
              ),
            );
          }
        }
      } else {
        warnings.add(
          ValidationWarning(
            path: 'eventsActions.${entry.key}',
            message: 'Expected an array of actions',
          ),
        );
      }
    }
  }

  void _validateAction(
    String path,
    Map<String, dynamic> action,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
    ValidationStats stats,
    Map<String, dynamic> contract,
  ) {
    stats.actions++;
    final type = action['action']?.toString();
    if (type == null || !supportedActions.contains(type)) {
      errors.add(
        ValidationError(
          path: '$path.action',
          message: 'Unsupported action type: $type',
        ),
      );
      return;
    }

    // Required params per action
    switch (type) {
      case 'navigate':
        if (action['route'] == null && (action['pageId'] == null)) {
          errors.add(
            ValidationError(
              path: path,
              message: 'navigate requires route or pageId',
            ),
          );
        }
        break;
      case 'apiCall':
        if (action['service'] == null || action['endpoint'] == null) {
          errors.add(
            ValidationError(
              path: path,
              message: 'apiCall requires service and endpoint',
            ),
          );
        }
        break;
      case 'updateState':
        final params = action['params'] as Map<String, dynamic>?;
        if (params == null || params['key'] == null) {
          errors.add(
            ValidationError(
              path: path,
              message: 'updateState requires params.key',
            ),
          );
        }
        break;
      case 'submitForm':
        // Recommended: formId or pageId
        if (action['formId'] == null &&
            (action['params']?['formId'] == null) &&
            action['pageId'] == null) {
          warnings.add(
            ValidationWarning(
              path: path,
              message: 'submitForm missing formId or pageId',
            ),
          );
        }
        break;
      default:
        break;
    }

    // Template resolution keys
    if (action.containsKey('params')) {
      final params = action['params'];
      if (params is Map<String, dynamic>) {
        for (final entry in params.entries) {
          final v = entry.value;
          if (v is String && !v.contains('\n')) {
            if (v.contains('\u0000')) continue;
            // Accept templates like ${state.key}
            if (_looksLikeTemplate(v) && !_isStateTemplate(v)) {
              warnings.add(
                ValidationWarning(
                  path: '$path.params.${entry.key}',
                  message: r'Suspicious template; expected ${state.*}',
                ),
              );
            }
          }
        }
      }
    }

    // Cross refs for apiCall targets
    if (type == 'apiCall') {
      final service = action['service']?.toString();
      final endpoint = action['endpoint']?.toString();
      final services = contract['services'] as Map<String, dynamic>?;
      if (service == null || endpoint == null || services == null) return;
      final svc = services[service] as Map<String, dynamic>?;
      if (svc == null) {
        errors.add(
          ValidationError(path: path, message: 'Unknown service: $service'),
        );
        return;
      }
      final endpoints = svc['endpoints'] as Map<String, dynamic>?;
      if (endpoints == null || !endpoints.containsKey(endpoint)) {
        errors.add(
          ValidationError(
            path: path,
            message: 'Unknown endpoint: $service.$endpoint',
          ),
        );
      }
    }
  }

  void _validateRoutes(
    Map<String, dynamic> pagesUi,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    final routes = Map<String, dynamic>.from(pagesUi['routes'] ?? {});
    final pages = Map<String, dynamic>.from(pagesUi['pages'] ?? {});
    for (final entry in routes.entries) {
      final route = entry.key;
      final cfg = entry.value as Map<String, dynamic>?;
      final pageId = cfg?['pageId']?.toString();
      if (pageId == null || !pages.containsKey(pageId)) {
        errors.add(
          ValidationError(
            path: 'pagesUI.routes.$route',
            message: 'Route pageId not found: $pageId',
          ),
        );
      }
    }
  }

  void _validateServices(
    Map<String, dynamic> contract,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    final services = Map<String, dynamic>.from(contract['services'] ?? {});
    final models = Map<String, dynamic>.from(contract['dataModels'] ?? {});
    for (final entry in services.entries) {
      final name = entry.key;
      final svc = Map<String, dynamic>.from(entry.value as Map);
      final endpoints = (svc['endpoints'] ?? {}) as Map<String, dynamic>;
      for (final e in endpoints.entries) {
        final endpointName = e.key;
        final cfg = e.value as Map<String, dynamic>;
        final schema = cfg['responseSchema'];
        if (schema is Map<String, dynamic>) {
          final type = schema['type'];
          final props = schema['properties'];
          if (type != 'object' || props is! Map<String, dynamic>) {
            errors.add(
              ValidationError(
                path: 'services.$name.endpoints.$endpointName.responseSchema',
                message: 'Schema must be an object with properties',
              ),
            );
            continue;
          }
          // Require data with array items $ref
          final dataProp = props['data'];
          if (dataProp is Map<String, dynamic>) {
            if (dataProp['type'] == 'array') {
              final items = dataProp['items'];
              final ref =
                  items is Map<String, dynamic>
                      ? items['\$ref']?.toString()
                      : null;
              if (ref == null || !_refExists(ref, models)) {
                errors.add(
                  ValidationError(
                    path:
                        'services.$name.endpoints.$endpointName.responseSchema.properties.data.items',
                    message: r'Missing or unknown $ref in items',
                  ),
                );
              }
            } else if (dataProp['\$ref'] is String) {
              final ref = dataProp['\$ref'] as String;
              if (!_refExists(ref, models)) {
                errors.add(
                  ValidationError(
                    path:
                        'services.$name.endpoints.$endpointName.responseSchema.properties.data',
                    message: r'Unknown $ref',
                  ),
                );
              }
            } else {
              warnings.add(
                ValidationWarning(
                  path:
                      'services.$name.endpoints.$endpointName.responseSchema.properties.data',
                  message: r'Prefer $ref to dataModels over raw types',
                ),
              );
            }
          } else {
            errors.add(
              ValidationError(
                path:
                    'services.$name.endpoints.$endpointName.responseSchema.properties',
                message: 'Missing required data property',
              ),
            );
          }
        } else {
          // Explicitly reject shorthand {"data": "array"}
          if (schema is Map == false && schema != null) {
            errors.add(
              ValidationError(
                path: 'services.$name.endpoints.$endpointName.responseSchema',
                message: 'Invalid schema structure',
              ),
            );
          }
        }
      }
    }
  }

  void _validateState(
    Map<String, dynamic> state,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    final global = Map<String, dynamic>.from(state['global'] ?? {});
    final pages = Map<String, dynamic>.from(state['pages'] ?? {});
    for (final entry in global.entries) {
      final field =
          entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : null;
      _validateStateField('state.global.${entry.key}', field, errors, warnings);
    }
    for (final pageEntry in pages.entries) {
      final fields =
          pageEntry.value is Map
              ? Map<String, dynamic>.from(pageEntry.value as Map)
              : <String, dynamic>{};
      for (final entry in fields.entries) {
        final field =
            entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : null;
        _validateStateField(
          'state.pages.${pageEntry.key}.${entry.key}',
          field,
          errors,
          warnings,
        );
      }
    }
  }

  void _validateStateField(
    String path,
    Map<String, dynamic>? field,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    if (field == null) {
      warnings.add(
        ValidationWarning(
          path: path,
          message: 'State field should be an object',
        ),
      );
      return;
    }
    final persistence = field['persistence']?.toString();
    if (persistence != null && !supportedPersistence.contains(persistence)) {
      errors.add(
        ValidationError(
          path: '$path.persistence',
          message: 'Unsupported persistence: $persistence',
        ),
      );
    }
    final type = field['type']?.toString();
    if (type != null &&
        !['string', 'number', 'boolean', 'object', 'array'].contains(type)) {
      warnings.add(
        ValidationWarning(
          path: '$path.type',
          message: 'Unexpected type: $type',
        ),
      );
    }
  }

  void _validateCrossReferences(
    Map<String, dynamic> contract,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    // Icons
    final mapping =
        (contract['assets']?['icons']?['mapping']) as Map<String, dynamic>?;
    if (mapping != null) {
      final pages =
          (contract['pagesUI']?['pages'] ?? {}) as Map<String, dynamic>;
      final used = <String>{};
      void collect(dynamic node) {
        if (node is Map<String, dynamic>) {
          final iconName = node['icon']?.toString() ?? node['name']?.toString();
          final type = node['type']?.toString();
          if (iconName != null && (type == 'icon' || type == 'iconButton')) {
            used.add(iconName);
          }
          for (final v in node.values) {
            collect(v);
          }
        } else if (node is List) {
          for (final v in node) {
            collect(v);
          }
        }
      }

      for (final page in pages.values) {
        collect(page);
      }
      for (final icon in used) {
        if (!mapping.containsKey(icon)) {
          warnings.add(
            ValidationWarning(
              path: 'assets.icons.mapping.$icon',
              message: 'Icon not mapped',
            ),
          );
        }
      }
    }
  }

  // Helpers
  bool _isStateBinding(String binding) =>
      RegExp(r'^\$\{state\.[^}]+\}$').hasMatch(binding);
  bool _isItemBinding(String binding) =>
      RegExp(r'^\$\{item\.[^}]+\}$').hasMatch(binding);
  bool _looksLikeItemField(String binding) =>
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_\.]*$').hasMatch(binding);
  bool _looksLikeTemplate(String v) => RegExp(r'^\$\{[^}]+\}$').hasMatch(v);
  bool _isStateTemplate(String v) =>
      RegExp(r'^\$\{state\.[^}]+\}$').hasMatch(v);
  bool _refExists(String ref, Map<String, dynamic> models) {
    if (!ref.startsWith('#/dataModels/')) return false;
    final key = ref.substring('#/dataModels/'.length);
    return models.containsKey(key);
  }
}

/// Internal doc feature extractor: parses docs to build supported lists.
class _DocFeatures {
  _DocFeatures._();
  static final _DocFeatures instance = _DocFeatures._().._init();

  final List<String> components = <String>[];
  final List<String> actions = <String>[];
  final List<String> validations = <String>[];

  void _init() {
    try {
      final dsl = File('docs/dsl_cheat_sheet.md');
      if (dsl.existsSync()) {
        final content = dsl.readAsLinesSync();
        for (var i = 0; i < content.length; i++) {
          final line = content[i].trim();
          if (line.contains('Supported `type` values:')) {
            // next line should be a bullet with comma-separated list
            final listLine =
                (i + 1 < content.length) ? content[i + 1].trim() : '';
            final list = listLine.replaceFirst(RegExp(r'^-\s*'), '');
            components.addAll(
              list.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
            );
          }
          if (line.contains('Allowed `action` values:')) {
            final listLine =
                (i + 1 < content.length) ? content[i + 1].trim() : '';
            final list = listLine.replaceFirst(RegExp(r'^-\s*'), '');
            actions.addAll(
              list.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
            );
          }
        }
      }
      final compRef = File('docs/components_reference.md');
      if (compRef.existsSync()) {
        final content = compRef.readAsLinesSync();
        for (final line in content) {
          final l = line.trim();
          if (l.startsWith('- Inline `validation`')) {
            final keysLine = l.split(':').last;
            final list =
                keysLine
                    .replaceAll('`', '')
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
            validations.addAll(list);
          }
        }
        if (!validations.contains('equal')) {
          // add cross-field example
          validations.add('equal');
        }
      }
    } catch (_) {
      // Silently fallback to constants.
    }
  }
}