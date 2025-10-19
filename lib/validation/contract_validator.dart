/// Validates the raw canonical contract JSON structure and collects errors.
class ContractValidator {
  /// Returns a list of human-readable errors. Empty list means valid enough.
  static List<String> validate(Map<String, dynamic> json) {
    final errors = <String>[];

    // Allowed DSL sets
    const allowedActions = {
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
    };
    const allowedComponents = {
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
    };
    const allowedPersistence = {
      'local',
      'device',
      'secure',
      'session',
      'memory',
    };

    // Helper to record type mismatches
    void expectMap(dynamic value, String path) {
      if (value != null && value is! Map) {
        errors.add("$path must be an object, got ${value.runtimeType}");
      }
    }

    void expectStringMap(dynamic value, String path) {
      if (value == null) return;
      if (value is! Map) {
        errors.add("$path must be an object of strings, got ${value.runtimeType}");
        return;
      }
      for (final entry in value.entries) {
        final v = entry.value;
        if (v != null && v is! String) {
          errors.add("$path['${entry.key}'] must be a string, got ${v.runtimeType}");
        }
      }
    }

    // Add other validators on demand as needed

    // Top-level sections
    expectMap(json['dataModels'], 'dataModels');
    expectMap(json['services'], 'services');
    expectMap(json['pagesUI'], 'pagesUI');
    expectMap(json['state'], 'state');
    expectMap(json['eventsActions'], 'eventsActions');
    expectMap(json['themingAccessibility'], 'themingAccessibility');
    expectMap(json['assets'], 'assets');
    expectMap(json['validations'], 'validations');
    expectMap(json['permissionsFlags'], 'permissionsFlags');
    expectMap(json['pagination'], 'pagination');

    // Theming tokens
    final theming = json['themingAccessibility'];
    if (theming is Map) {
      final tokens = theming['tokens'];
      if (tokens is Map) {
        for (final themeEntry in tokens.entries) {
          final themeName = themeEntry.key;
          final themeTokens = themeEntry.value;
          if (themeTokens is Map) {
            expectStringMap(themeTokens, 'themingAccessibility.tokens.$themeName');
          } else {
            errors.add(
              'themingAccessibility.tokens.$themeName must be an object of strings, got ${themeTokens.runtimeType}',
            );
          }
        }
      } else if (tokens != null) {
        errors.add('themingAccessibility.tokens must be an object, got ${tokens.runtimeType}');
      }
    }

    // Assets icons mapping
    final assets = json['assets'];
    if (assets is Map) {
      final icons = assets['icons'];
      if (icons is Map) {
        final mapping = icons['mapping'];
        if (mapping != null) {
          expectStringMap(mapping, 'assets.icons.mapping');
        }
      }
    }

    // Services endpoints
    final services = json['services'];
    if (services is Map) {
      for (final entry in services.entries) {
        final service = entry.value;
        if (service is Map) {
          expectMap(service['endpoints'], 'services.${entry.key}.endpoints');
        }
      }
    }

    // PagesUI structure
    final pagesUI = json['pagesUI'];
    if (pagesUI is Map) {
      expectMap(pagesUI['pages'], 'pagesUI.pages');
      expectMap(pagesUI['routes'], 'pagesUI.routes');
      if (pagesUI['bottomNavigation'] != null && pagesUI['bottomNavigation'] is! Map) {
        errors.add('pagesUI.bottomNavigation must be an object, got ${pagesUI['bottomNavigation'].runtimeType}');
      }
    }

    // Validate actions and components recursively across JSON
    void scan(Object? node, String path) {
      bool isUnder(String section) => path.startsWith('root.' + section) || path.contains('.' + section + '.');
      final underPagesUI = isUnder('pagesUI');
      final underEvents = isUnder('eventsActions');

      if (node is Map) {
        // Component type (only validate inside pagesUI subtree)
        if (underPagesUI && node.containsKey('type') && node['type'] is String) {
          final type = node['type'] as String;
          if (type.isNotEmpty && !allowedComponents.contains(type)) {
            errors.add("Unsupported component type '$type' at $path.type");
          }
        }
        // Action name (validate inside pagesUI and eventsActions subtrees)
        if ((underPagesUI || underEvents) && node.containsKey('action') && node['action'] is String) {
          final action = node['action'] as String;
          if (action.isNotEmpty && !allowedActions.contains(action)) {
            errors.add("Unsupported action '$action' at $path.action");
          }
        }
        // Recurse into children
        for (final entry in node.entries) {
          final key = entry.key;
          final value = entry.value;
          scan(value, '$path.$key');
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          scan(node[i], '$path[$i]');
        }
      }
    }
    scan(json, 'root');

    // Validate state persistence policies
    final state = json['state'];
    if (state is Map) {
      final global = state['global'];
      if (global is Map) {
        for (final entry in global.entries) {
          final field = entry.value;
          if (field is Map) {
            final persistence = field['persistence'];
            if (persistence != null && persistence is String &&
                !allowedPersistence.contains(persistence)) {
              errors.add(
                "state.global['${entry.key}'].persistence must be one of ${allowedPersistence.join(', ')}, got '$persistence'",
              );
            }
          }
        }
      }
      final pages = state['pages'];
      if (pages is Map) {
        for (final pageEntry in pages.entries) {
          final pageId = pageEntry.key;
          final fields = pageEntry.value;
          if (fields is Map) {
            for (final fieldEntry in fields.entries) {
              final field = fieldEntry.value;
              if (field is Map) {
                final persistence = field['persistence'];
                if (persistence != null && persistence is String &&
                    !allowedPersistence.contains(persistence)) {
                  errors.add(
                    "state.pages.$pageId['${fieldEntry.key}'].persistence must be one of ${allowedPersistence.join(', ')}, got '$persistence'",
                  );
                }
              }
            }
          }
        }
      }
    }

    return errors;
  }
}