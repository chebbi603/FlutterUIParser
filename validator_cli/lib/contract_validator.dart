library contract_validator;

import 'dart:convert';

class ValidationIssue {
  final String path;
  final String message;
  final String severity; // 'error' | 'warning'
  ValidationIssue(this.path, this.message, this.severity);
}

class ValidationResult {
  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;
  ValidationResult({required this.errors, required this.warnings});
  bool get isValid => errors.isEmpty;
}

class ContractValidator {
  static const _allowedLayouts = {
    'scroll', 'column', 'row', 'center', 'grid', 'list', 'hero'
  };

  static const _allowedComponentTypes = {
    'text', 'textField', 'button', 'textButton', 'iconButton', 'icon', 'image',
    'card', 'list', 'grid', 'row', 'column', 'center', 'hero', 'form',
    'searchBar', 'chip', 'progressIndicator', 'switch', 'slider', 'audio', 'video', 'webview'
  };

  static const _allowedActionTypes = {
    'navigate', 'pop', 'openUrl', 'apiCall', 'updateState', 'showError',
    'showSuccess', 'submitForm', 'refreshData', 'showBottomSheet', 'showDialog', 'clearCache'
  };

  static const _allowedStateTypes = {
    'string', 'number', 'boolean', 'object', 'array'
  };

  static const _allowedPersistence = {
    'memory', 'session', 'local', 'secure'
  };

  static ValidationResult validate(Map<String, dynamic> contract, {Map<String, dynamic>? schema}) {
    final errors = <ValidationIssue>[];
    final warnings = <ValidationIssue>[];

    void err(String path, String msg) => errors.add(ValidationIssue(path, msg, 'error'));
    void warn(String path, String msg) => warnings.add(ValidationIssue(path, msg, 'warning'));

    // Optional schema presence notice (we do not evaluate JSON Schema here)
    if (schema != null) {
      warn('schema', 'Schema provided; this validator uses rule-based checks (no JSON Schema evaluation).');
    }

    // meta
    final meta = _asMap(contract['meta']);
    if (meta == null) {
      err('meta', 'Missing meta object');
    } else {
      for (final key in ['appName', 'version', 'schemaVersion']) {
        if (meta[key] is! String || (meta[key] as String).isEmpty) {
          err('meta.$key', 'Required string');
        }
      }
      if (meta['generatedAt'] != null && meta['generatedAt'] is! String) {
        warn('meta.generatedAt', 'Expected ISO-8601 string');
      }
      if (meta['authors'] != null && meta['authors'] is! List) {
        warn('meta.authors', 'Expected array of strings');
      }
    }

    // services
    final services = _asMap(contract['services']);
    if (services != null) {
      services.forEach((svcName, svcVal) {
        final svc = _asMap(svcVal);
        if (svc == null) {
          err('services.$svcName', 'Service must be an object');
          return;
        }
        if (svc['baseUrl'] is! String) {
          err('services.$svcName.baseUrl', 'Required string');
        }
        final endpoints = _asMap(svc['endpoints']);
        if (endpoints == null) {
          err('services.$svcName.endpoints', 'Required object');
        } else {
          endpoints.forEach((epName, epVal) {
            final ep = _asMap(epVal);
            if (ep == null) {
              err('services.$svcName.endpoints.$epName', 'Endpoint must be an object');
              return;
            }
            if (ep['path'] is! String) {
              err('services.$svcName.endpoints.$epName.path', 'Required string');
            }
            const methods = {'GET','POST','PUT','PATCH','DELETE'};
            if (ep['method'] is! String || !methods.contains(ep['method'])) {
              err('services.$svcName.endpoints.$epName.method', 'Must be one of ${methods.join(', ')}');
            }
            // Encourage schema presence
            if (ep['responseSchema'] == null) {
              warn('services.$svcName.endpoints.$epName.responseSchema', 'Consider providing a JSON Schema for responses');
            } else if (!_isMap(ep['responseSchema'])) {
              warn('services.$svcName.endpoints.$epName.responseSchema', 'Expected an object');
            }
          });
        }
      });
    }

    // pagesUI
    final pagesUI = _asMap(contract['pagesUI']);
    if (pagesUI == null) {
      err('pagesUI', 'Missing pagesUI object');
    } else {
      final pages = _asMap(pagesUI['pages']);
      if (pages == null) {
        err('pagesUI.pages', 'Required object');
      } else {
        pages.forEach((pageId, pageVal) {
          final page = _asMap(pageVal);
          if (page == null) {
            err('pagesUI.pages.$pageId', 'Page must be an object');
            return;
          }
          if (page['id'] is! String) {
            err('pagesUI.pages.$pageId.id', 'Required string');
          }
          if (page['title'] is! String) {
            err('pagesUI.pages.$pageId.title', 'Required string');
          }
          final layout = page['layout'];
          if (layout is! String || !_allowedLayouts.contains(layout)) {
            err('pagesUI.pages.$pageId.layout', 'Unsupported layout "$layout"');
          }
          if (page['navigationBar'] != null && !_isMap(page['navigationBar'])) {
            warn('pagesUI.pages.$pageId.navigationBar', 'Expected object');
          }
          final children = page['children'];
          if (children is! List) {
            err('pagesUI.pages.$pageId.children', 'Required array of components');
          } else {
            for (var i = 0; i < children.length; i++) {
              _validateComponent(children[i], 'pagesUI.pages.$pageId.children[$i]', err, warn);
            }
          }
        });
      }

      // routes reference existing pages
      final routes = _asMap(pagesUI['routes']);
      if (routes != null && pagesUI['pages'] is Map) {
        routes.forEach((route, routeVal) {
          final r = _asMap(routeVal);
          if (r == null) {
            err('pagesUI.routes.$route', 'Route must be an object');
            return;
          }
          final pageId = r['pageId'];
          if (pageId is! String) {
            err('pagesUI.routes.$route.pageId', 'Required string');
          } else if (!(pagesUI['pages'] as Map).containsKey(pageId)) {
            err('pagesUI.routes.$route.pageId', 'References unknown page "$pageId"');
          }
        });
      }

      // bottomNavigation icons must be mapped
      final iconNamesUsed = <String>{};
      final bottomNav = _asMap(pagesUI['bottomNavigation']);
      if (bottomNav != null) {
        final items = bottomNav['items'];
        if (items is List) {
          for (final it in items) {
            final item = _asMap(it);
            if (item != null && item['icon'] is String) {
              iconNamesUsed.add(item['icon'] as String);
            }
          }
        }
      }

      // collect icons from components too
      if (pagesUI['pages'] is Map) {
        (pagesUI['pages'] as Map).forEach((pageId, pageVal) {
          final page = _asMap(pageVal);
          if (page == null) return;
          final children = page['children'];
          if (children is List) {
            _collectIcons(children, iconNamesUsed);
          }
        });
      }

      // Verify mapping exists for used icons
      final assets = _asMap(contract['assets']);
      final icons = assets == null ? null : _asMap(assets['icons']);
      final mapping = icons == null ? null : _asMap(icons['mapping']);
      for (final name in iconNamesUsed) {
        if (mapping == null || !mapping.containsKey(name)) {
          warn('assets.icons.mapping.$name', 'Icon "$name" is used but not mapped');
        }
      }
    }

    // state
    final state = _asMap(contract['state']);
    if (state != null) {
      final global = _asMap(state['global']);
      if (global != null) {
        global.forEach((key, val) {
          _validateStateField(val, 'state.global.$key', err, warn);
        });
      }
      final pages = _asMap(state['pages']);
      if (pages != null) {
        pages.forEach((pid, fieldsVal) {
          final fields = _asMap(fieldsVal);
          if (fields == null) {
            err('state.pages.$pid', 'Expected object of fields');
          } else {
            fields.forEach((key, val) {
              _validateStateField(val, 'state.pages.$pid.$key', err, warn);
            });
          }
        });
      }
    }

    // themingAccessibility tokens check
    final theming = _asMap(contract['themingAccessibility']);
    if (theming != null) {
      final tokens = _asMap(theming['tokens']);
      for (final mode in ['light', 'dark']) {
        final m = tokens == null ? null : _asMap(tokens[mode]);
        if (m == null) continue;
        for (final k in ['primary', 'surface', 'onSurface', 'error']) {
          if (m[k] is! String) {
            warn('themingAccessibility.tokens.$mode.$k', 'Expected color string');
          }
        }
      }
    }

    // validations (light checks)
    final validations = _asMap(contract['validations']);
    if (validations != null) {
      final rules = _asMap(validations['rules']);
      if (rules != null) {
        rules.forEach((rid, ruleVal) {
          if (!_isMap(ruleVal)) {
            warn('validations.rules.$rid', 'Expected object');
          }
        });
      }
    }

    // permissionsFlags (light checks)
    final perms = _asMap(contract['permissionsFlags']);
    if (perms != null) {
      final roles = _asMap(perms['roles']);
      if (roles != null) {
        roles.forEach((role, roleVal) {
          final r = _asMap(roleVal);
          if (r == null) return;
          if (r['permissions'] != null && r['permissions'] is! List) {
            warn('permissionsFlags.roles.$role.permissions', 'Expected array');
          }
          if (r['inherits'] != null && r['inherits'] is! List) {
            warn('permissionsFlags.roles.$role.inherits', 'Expected array');
          }
        });
      }
    }

    return ValidationResult(errors: errors, warnings: warnings);
  }

  static void _validateComponent(
    dynamic val,
    String path,
    void Function(String, String) err,
    void Function(String, String) warn,
  ) {
    final comp = _asMap(val);
    if (comp == null) {
      err(path, 'Component must be an object');
      return;
    }
    final type = comp['type'];
    if (type is! String || !_allowedComponentTypes.contains(type)) {
      err('$path.type', 'Unsupported component type "$type"');
    }
    if (comp['style'] != null && !_isMap(comp['style'])) {
      warn('$path.style', 'Expected object');
    }

    // Event actions
    for (final ev in ['onTap', 'onChanged', 'onSubmit']) {
      if (comp[ev] != null) {
        _validateAction(comp[ev], '$path.$ev', err, warn);
      }
    }

    // Component-specific hints
    if (type == 'image') {
      if (comp['src'] == null && comp['url'] == null && comp['text'] == null) {
        warn('$path', 'Image missing src/url/text');
      }
      if (comp['text'] != null) {
        warn('$path.text', 'Prefer "src" (or "url") over "text" for image URLs');
      }
    }

    // children
    if (comp['children'] != null) {
      final children = comp['children'];
      if (children is! List) {
        warn('$path.children', 'Expected array');
      } else {
        for (var i = 0; i < children.length; i++) {
          _validateComponent(children[i], '$path.children[$i]', err, warn);
        }
      }
    }
  }

  static void _validateAction(
    dynamic val,
    String path,
    void Function(String, String) err,
    void Function(String, String) warn,
  ) {
    final act = _asMap(val);
    if (act == null) {
      err(path, 'Action must be an object');
      return;
    }
    final action = act['action'];
    if (action is! String || !_allowedActionTypes.contains(action)) {
      err('$path.action', 'Unsupported action "$action"');
      return;
    }

    switch (action) {
      case 'navigate':
        if (act['route'] is! String) {
          err('$path.route', 'Required string for navigate');
        }
        break;
      case 'openUrl':
        final params = _asMap(act['params']);
        if (params == null || params['url'] is! String) {
          err('$path.params.url', 'Required string for openUrl');
        }
        break;
      case 'apiCall':
        if (act['service'] is! String) {
          err('$path.service', 'Required string for apiCall');
        }
        if (act['endpoint'] is! String) {
          err('$path.endpoint', 'Required string for apiCall');
        }
        break;
      case 'updateState':
        final key = act['key'] ?? _asMap(act['params'])?['key'];
        if (key is! String) {
          err('$path.key', 'Provide "key" or params.key for updateState');
        }
        break;
      case 'submitForm':
        final formId = act['formId'] ?? _asMap(act['params'])?['formId'] ?? act['pageId'];
        if (formId is! String) {
          err('$path.formId', 'Provide formId (or params.formId/pageId) for submitForm');
        }
        break;
      default:
        // showError/showSuccess/showDialog/etc: basic presence suffices
        break;
    }
  }

  static void _validateStateField(
    dynamic val,
    String path,
    void Function(String, String) err,
    void Function(String, String) warn,
  ) {
    final field = _asMap(val);
    if (field == null) {
      err(path, 'Expected object');
      return;
    }
    final type = field['type'];
    if (type is! String || !_allowedStateTypes.contains(type)) {
      err('$path.type', 'Unsupported state type "$type"');
    }
    final persistence = field['persistence'];
    if (persistence != null && (persistence is! String || !_allowedPersistence.contains(persistence))) {
      err('$path.persistence', 'Unsupported persistence "$persistence"');
    }
  }

  static void _collectIcons(List<dynamic> children, Set<String> out) {
    for (final c in children) {
      final comp = _asMap(c);
      if (comp == null) continue;
      if (comp['type'] == 'icon' && comp['name'] is String) {
        out.add(comp['name'] as String);
      }
      if (comp['children'] is List) {
        _collectIcons(comp['children'] as List<dynamic>, out);
      }
    }
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) {
      return v.cast<String, dynamic>();
    }
    return null;
  }

  static bool _isMap(dynamic v) => v is Map;
}