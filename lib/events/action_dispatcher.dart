// ignore_for_file: use_build_context_synchronously
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/config_models.dart';
import '../services/api_service.dart';
import '../state/state_manager.dart';
import '../navigation/navigation_bridge.dart';

/// Enhanced action dispatcher with comprehensive action support
class EnhancedActionDispatcher {
  static final ContractApiService _apiService = ContractApiService();
  static final EnhancedStateManager _stateManager = EnhancedStateManager();

  /// Execute action based on configuration
  static Future<void> execute(
    BuildContext context,
    ActionConfig config, [
    Map<String, dynamic>? additionalData,
  ]) async {
    try {
      switch (config.action) {
        case 'navigate':
          await _handleNavigate(context, config);
          break;
        case 'pop':
          await _handlePop(context, config);
          break;
        case 'openUrl':
          await _handleOpenUrl(config);
          break;
        case 'apiCall':
          await _handleApiCall(context, config, additionalData);
          break;
        case 'updateState':
          await _handleUpdateState(config, additionalData);
          break;
        case 'showError':
          await _handleShowError(context, config);
          break;
        case 'showSuccess':
          await _handleShowSuccess(context, config);
          break;
        case 'submitForm':
          await _handleSubmitForm(context, config);
          break;
        case 'refreshData':
          await _handleRefreshData(context, config);
          break;
        case 'showBottomSheet':
          await _handleShowBottomSheet(context, config);
          break;
        case 'showDialog':
          await _handleShowDialog(context, config);
          break;
        case 'clearCache':
          await _handleClearCache();
          break;
        default:
          debugPrint('Unknown action: ${config.action}');
          break;
      }
    } catch (e) {
      debugPrint('Error executing action ${config.action}: $e');

      // Execute error callback if provided
      if (config.onError != null) {
        await execute(context, config.onError!);
      } else {
        // Show default error
        await _showDefaultError(context, e.toString());
      }
    }
  }

  static Future<void> _handleNavigate(
    BuildContext context,
    ActionConfig config,
  ) async {
    final route = config.route ?? config.params?['route']?.toString();
    if (route == null) return;

    final replace = config.params?['replace'] == true;
    final data = config.params?['data'];

    final switched = NavigationBridge.switchTo(route);
    if (switched) {
      return;
    }

    if (replace) {
      Navigator.of(context).pushReplacementNamed(route, arguments: data);
    } else {
      Navigator.of(context).pushNamed(route, arguments: data);
    }
  }

  static Future<void> _handlePop(
    BuildContext context,
    ActionConfig config,
  ) async {
    final result = config.params?['result'];
    Navigator.of(context).pop(result);
  }

  static Future<void> _handleOpenUrl(ActionConfig config) async {
    final url = config.params?['url']?.toString();
    if (url == null) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _handleApiCall(
    BuildContext context,
    ActionConfig config,
    Map<String, dynamic>? additionalData,
  ) async {
    String? service = config.service ?? config.params?['service']?.toString();
    String? endpoint = config.endpoint ?? config.params?['endpoint']?.toString();

    // Resolve template variables in service/endpoint if provided as templates
    service = _resolveTemplateString(service);
    endpoint = _resolveTemplateString(endpoint);

    if (service == null || endpoint == null) return;

    // Merge additional data with params
    final data = <String, dynamic>{};
    if (config.params != null) {
      data.addAll(_resolveTemplates(config.params!));
    }
    if (additionalData != null) {
      data.addAll(_resolveTemplates(additionalData));
    }

    final response = await _apiService.call(
      service: service,
      endpoint: endpoint,
      data: data,
    );

    // Execute success callback
    if (config.onSuccess != null) {
      await execute(context, config.onSuccess!, {'response': response});
    }
  }

  /// Resolve `${state.*}` templates in a map recursively.
  static Map<String, dynamic> _resolveTemplates(Map<String, dynamic> input) {
    final resolved = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is String) {
        resolved[key] = _resolveTemplateString(value);
      } else if (value is Map) {
        resolved[key] = _resolveTemplates(Map<String, dynamic>.from(value));
      } else if (value is List) {
        resolved[key] = value
            .map((v) => v is String
                ? _resolveTemplateString(v)
                : (v is Map
                    ? _resolveTemplates(Map<String, dynamic>.from(v))
                    : v))
            .toList();
      } else {
        resolved[key] = value;
      }
    }
    return resolved;
  }

  /// Resolve a single template string if it matches `${state.<key>}`.
  static String? _resolveTemplateString(String? value) {
    if (value == null) return null;
    final regex = RegExp(r'^\$\{state\.(.+)\}$');
    final match = regex.firstMatch(value);
    if (match != null) {
      final stateKey = match.group(1)!;
      final resolved = _stateManager.getState(stateKey);
      return resolved?.toString();
    }
    return value;
  }

  static Future<void> _handleUpdateState(
    ActionConfig config,
    Map<String, dynamic>? additionalData,
  ) async {
    final key = config.key ?? config.params?['key']?.toString();
    if (key == null) return;

    dynamic value = config.value ?? config.params?['value'];

    // Use additional data if value not specified
    if (value == null && additionalData != null) {
      value = additionalData['value'];
    }

    final scope = config.scope ?? config.params?['scope']?.toString();

    if (scope == 'global') {
      await _stateManager.setGlobalState(key, value);
    } else {
      await _stateManager.setState(key, value);
    }
  }

  static Future<void> _handleShowError(
    BuildContext context,
    ActionConfig config,
  ) async {
    final message =
        config.params?['message']?.toString() ?? 'An error occurred';

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  static Future<void> _handleShowSuccess(
    BuildContext context,
    ActionConfig config,
  ) async {
    final message = config.params?['message']?.toString() ?? 'Success';

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  static Future<void> _handleSubmitForm(
    BuildContext context,
    ActionConfig config,
  ) async {
    final formId =
        config.params?['formId']?.toString() ??
        config.params?['pageId']?.toString() ??
        config.key;
    if (formId == null || formId.isEmpty) return;

    // Gather page state for the given form/page id
    final data = _stateManager.getAllPageState(formId);

    // If service/endpoint provided, persist to backend with collected form data
    final service = config.service ?? config.params?['service']?.toString();
    final endpoint = config.endpoint ?? config.params?['endpoint']?.toString();
    if (service != null && endpoint != null) {
      // Merge any static params with form data for request body
      final payload = <String, dynamic>{};
      if (config.params != null) {
        payload.addAll(_resolveTemplates(config.params!));
      }
      payload.addAll(_resolveTemplates(data));

      final response = await _apiService.call(
        service: service,
        endpoint: endpoint,
        data: payload,
      );

      // Execute success callback if provided
      if (config.onSuccess != null) {
        await execute(context, config.onSuccess!, {'response': response});
      }
    }

    // Build display content
    final buffer = StringBuffer();
    if (data.isEmpty) {
      buffer.write('No data entered.');
    } else {
      final keys = data.keys.toList()..sort();
      for (final k in keys) {
        final v = data[k];
        buffer.writeln('$k: ${v ?? ''}');
      }
    }

    // Show popup with form content
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title:
                Text(
                  config.params?['title']?.toString() ?? 'Form Submitted',
                ),
            content: Text(buffer.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  static Future<void> _handleRefreshData(
    BuildContext context,
    ActionConfig config,
  ) async {
    final listId = config.params?['listId']?.toString();
    if (listId == null) return;

    // In a real implementation, you'd refresh the specific list
    debugPrint('Refreshing data for list: $listId');
  }

  static Future<void> _handleShowBottomSheet(
    BuildContext context,
    ActionConfig config,
  ) async {
    final content = config.params?['content']?.toString();

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(content ?? 'Bottom Sheet'),
                const SizedBox(height: 16),
                CupertinoButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
    );
  }

  static Future<void> _handleShowDialog(
    BuildContext context,
    ActionConfig config,
  ) async {
    final title = config.params?['title']?.toString() ?? 'Dialog';
    final message = config.params?['message']?.toString() ?? '';

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: message.isNotEmpty ? Text(message) : null,
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  static Future<void> _handleClearCache() async {
    _apiService.clearCache();
  }

  static Future<void> _showDefaultError(
    BuildContext context,
    String error,
  ) async {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(error),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }
}
