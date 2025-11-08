// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/config_models.dart';
import '../services/api_service.dart';
import '../state/state_manager.dart';
import '../navigation/navigation_bridge.dart';
import '../events/event_bus.dart';
import '../events/action_middleware.dart';
import '../services/auth_service.dart';
import '../providers/contract_provider.dart';
import '../analytics/services/analytics_service.dart';
import '../analytics/models/tracking_event.dart';

/// Enhanced action dispatcher with comprehensive action support
class EnhancedActionDispatcher {
  static final ContractApiService _apiService = ContractApiService();
  static final EnhancedStateManager _stateManager = EnhancedStateManager();
  static Map<String, dynamic>? _lastAdditionalData;

  /// Execute action based on configuration
  static Future<void> execute(
    BuildContext context,
    ActionConfig config, [
    Map<String, dynamic>? additionalData,
  ]) async {
    final bus = EventBus();
    final middleware = ActionMiddlewarePipeline();
    final ctx = <String, dynamic>{'additionalData': additionalData};
    try {
      // Loading state support
      final String? loadingKey = config.params?['loadingKey']?.toString();
      if (loadingKey != null) {
        await _stateManager.setGlobalState(loadingKey, true);
      }
      bus.emit(ActionStarted(config.action, ctx));
      await middleware.runBefore(config, ctx);

      // Keep track of the latest additional data (e.g., response)
      _lastAdditionalData = additionalData;

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
        case 'authLogin':
          await _handleAuthLogin(context, config);
          break;
        case 'authLogout':
          await _handleAuthLogout(context, config);
          break;
        case 'updateState':
          await _handleUpdateState(config, additionalData);
          break;
        case 'undo':
          await _handleUndo(config);
          break;
        case 'redo':
          await _handleRedo(config);
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
        case 'sequence':
          await _handleSequence(context, config, additionalData);
          break;
        case 'setAuthToken':
          await _handleSetAuthToken(config, additionalData);
          break;
        default:
          debugPrint('Unknown action: ${config.action}');
          break;
      }

      await middleware.runAfter(config, ctx);
      bus.emit(ActionCompleted(config.action));
      if (loadingKey != null) {
        await _stateManager.setGlobalState(loadingKey, false);
      }
    } catch (e) {
      await middleware.runOnError(config, e, ctx);
      bus.emit(ActionFailed(config.action, e));
      debugPrint('Error executing action ${config.action}: $e');

      // Execute error callback if provided, passing error details
      if (config.onError != null) {
        await execute(context, config.onError!, {'error': e});
      } else {
        // Show default error
        await _showDefaultError(context, e.toString());
      }

      final String? loadingKey = config.params?['loadingKey']?.toString();
      if (loadingKey != null) {
        await _stateManager.setGlobalState(loadingKey, false);
      }
    }
  }

  static Future<void> _handleAuthLogout(
    BuildContext context,
    ActionConfig config,
  ) async {
    // Attempt server-side logout via AuthService (best effort)
    final authService = AuthService(_stateManager, _apiService);
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      authService.attachContractProvider(provider);
    } catch (_) {}
    try {
      await authService.logout();
    } catch (_) {}

    // Clear all persisted and in-memory state, including page-scoped fields
    await _stateManager.clearAll();

    // Log analytics logout event
    AnalyticsService().logAuthEvent('logout', {});

    // Navigate to login page at the root navigator and clear stack
    final switched = NavigationBridge.switchTo('/login');
    if (!switched) {
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
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

  static Future<void> _handleAuthLogin(
    BuildContext context,
    ActionConfig config,
  ) async {
    final formId =
        config.params?['formId']?.toString() ?? config.key ?? 'login';
    final data = _stateManager.getAllPageState(formId);
    final email = (data['email'] ?? config.params?['email'])?.toString();
    final password = (data['password'] ?? config.params?['password'])?.toString();

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      await _handleShowError(
        context,
        ActionConfig(action: 'showError', params: {
          'message': 'Missing credentials',
        }),
      );
      AnalyticsService().logAuthEvent('login_failed', {
        'reason': 'missing_credentials',
      });
      return;
    }

    final authService = AuthService(_stateManager, _apiService);
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      authService.attachContractProvider(provider);
    } catch (_) {}

    final ok = await authService.login(email: email, password: password);
    final analytics = AnalyticsService();
    if (ok) {
      final userObj = _stateManager.getGlobalState<Map<String, dynamic>>('user');
      final uid = userObj?['id']?.toString();
      analytics.logAuthEvent('user_authenticated', {
        if (uid != null) 'userId': uid,
        'loginMethod': 'email',
      });

      // Prefer switching tabs when available; otherwise return to app root
      // so the home scaffold rebuilds with bottom navigation enabled.
      final switched = NavigationBridge.switchTo('/home');
      if (!switched) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      await _handleShowError(
        context,
        ActionConfig(action: 'showError', params: {
          'message': 'Invalid email or password',
        }),
      );
      analytics.logAuthEvent('login_failed', {
        'reason': 'invalid_credentials',
      });
    }
  }

  static Future<void> _handleApiCall(
    BuildContext context,
    ActionConfig config,
    Map<String, dynamic>? additionalData,
  ) async {
    String? service = config.service ?? config.params?['service']?.toString();
    String? endpoint =
        config.endpoint ?? config.params?['endpoint']?.toString();

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

    // Apply optimistic state updates if configured
    final optimistic = config.params?['optimisticState'];
    Map<String, dynamic>? previousValues;
    if (optimistic is Map<String, dynamic>) {
      previousValues = {};
      // Capture previous values and apply new ones
      for (final entry in optimistic.entries) {
        final key = entry.key;
        final newValue = entry.value;
        final oldValue = _stateManager.getState(key);
        previousValues[key] = oldValue;
        await _stateManager.setState(key, newValue);
      }
    }

    try {
      // Special-case: route analytics trackEvent via AnalyticsService batching
      final serviceKey = service.toLowerCase();
      final endpointKey = endpoint.toLowerCase();
      if ((serviceKey == 'analytics' || serviceKey == 'analyticsservice') && endpointKey == 'trackevent') {
        final analytics = AnalyticsService();
        final ev = data['event']?.toString();
        final feature = data['feature']?.toString();
        final actionName = data['action']?.toString();
        final componentId = feature ?? actionName ?? ev ?? 'unknown';

        analytics.trackComponentInteraction(
          componentId: componentId,
          componentType: feature != null ? 'feature' : 'component',
          eventType: TrackingEventType.tap,
          data: {
            if (ev != null) 'event': ev,
            if (feature != null) 'feature': feature,
            if (actionName != null) 'action': actionName,
          },
        );

        // Flush immediately to ensure visibility in backend collections
        await analytics.flush();

        // Execute success callback if provided
        if (config.onSuccess != null) {
          await execute(context, config.onSuccess!, {'response': {'ok': true}});
        }
        return;
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
    } catch (e) {
      // Roll back optimistic updates on failure
      if (previousValues != null) {
        for (final entry in previousValues.entries) {
          await _stateManager.setState(entry.key, entry.value);
        }
      }
      rethrow;
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
        resolved[key] =
            value
                .map(
                  (v) =>
                      v is String
                          ? _resolveTemplateString(v)
                          : (v is Map
                              ? _resolveTemplates(Map<String, dynamic>.from(v))
                              : v),
                )
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
    // Resolve full response object
    if (value == '\${response}') {
      if (_lastAdditionalData != null) {
        final resp = _lastAdditionalData!['response'];
        try {
          return json.encode(resp);
        } catch (_) {
          return resp?.toString();
        }
      }
    }
    // Resolve full error object
    if (value == '\${error}') {
      if (_lastAdditionalData != null) {
        final err = _lastAdditionalData!['error'];
        try {
          return err?.toString();
        } catch (_) {
          return err != null ? '$err' : null;
        }
      }
    }
    // Resolve from state
    final stateRegex = RegExp(r'^\$\{state\.(.+)\}$');
    final stateMatch = stateRegex.firstMatch(value);
    if (stateMatch != null) {
      final stateKey = stateMatch.group(1)!;
      final resolved = _stateManager.getState(stateKey);
      return resolved?.toString();
    }
    // Resolve from response
    final respRegex = RegExp(r'^\$\{response\.(.+)\}$');
    final respMatch = respRegex.firstMatch(value);
    if (respMatch != null && _lastAdditionalData != null) {
      final path = respMatch.group(1)!;
      dynamic current = _lastAdditionalData!['response'];
      for (final segment in path.split('.')) {
        if (current is Map<String, dynamic>) {
          current = current[segment];
        } else {
          current = null;
          break;
        }
      }
      return current?.toString();
    }
    // Resolve from error
    final errRegex = RegExp(r'^\$\{error\.(.+)\}$');
    final errMatch = errRegex.firstMatch(value);
    if (errMatch != null && _lastAdditionalData != null) {
      final path = errMatch.group(1)!;
      dynamic current = _lastAdditionalData!['error'];
      // Try common fields like message/statusCode via dynamic
      if (current != null) {
        try {
          if (path == 'message') {
            final msg = (current as dynamic).message;
            if (msg != null) return msg.toString();
          }
          if (path == 'statusCode') {
            final code = (current as dynamic).statusCode;
            if (code != null) return code.toString();
          }
        } catch (_) {}
      }
      // If error is a map, resolve nested fields
      for (final segment in path.split('.')) {
        if (current is Map<String, dynamic>) {
          current = current[segment];
        } else {
          current = null;
          break;
        }
      }
      return current?.toString();
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

    // Resolve templates for string values
    if (value is String) {
      value = _resolveTemplateString(value);
    }

    if (scope == 'global') {
      await _stateManager.setGlobalState(key, value);
    } else {
      await _stateManager.setState(key, value);
    }
  }

  static Future<void> _handleSequence(
    BuildContext context,
    ActionConfig config,
    Map<String, dynamic>? additionalData,
  ) async {
    final steps = config.params?['steps'];
    if (steps is List) {
      for (final step in steps) {
        if (step is Map<String, dynamic>) {
          final next = ActionConfig.fromJson(step);
          await execute(context, next, additionalData);
        }
      }
    }
  }

  static Future<void> _handleSetAuthToken(
    ActionConfig config,
    Map<String, dynamic>? additionalData,
  ) async {
    dynamic value = config.value ?? config.params?['value'];
    if (value is String) {
      value = _resolveTemplateString(value);
    }
    if (value is! String || value.isEmpty) return;
    // Update API service and global state
    _apiService.setAuthToken(value);
    await _stateManager.setGlobalState('authToken', value);
  }

  static Future<void> _handleShowError(
    BuildContext context,
    ActionConfig config,
  ) async {
    final message =
        _resolveTemplateString(config.params?['message']?.toString()) ??
        'An error occurred';

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
      // Special-case: Auth login flow via AuthService to persist tokens/state
      if (service == 'auth' && endpoint == 'login') {
        final email = data['email']?.toString() ?? config.params?['email']?.toString();
        final password = data['password']?.toString() ?? config.params?['password']?.toString();
        if (email == null || email.isEmpty || password == null || password.isEmpty) {
          await _handleShowError(
            context,
            ActionConfig(action: 'showError', params: {
              'message': 'Missing credentials',
            }),
          );
          AnalyticsService().logAuthEvent('login_failed', {
            'reason': 'missing_credentials',
          });
          return;
        }

        final authService = AuthService(_stateManager, _apiService);
        try {
          final provider = Provider.of<ContractProvider>(context, listen: false);
          authService.attachContractProvider(provider);
        } catch (_) {}

        final ok = await authService.login(email: email, password: password);
        final analytics = AnalyticsService();
        if (ok) {
          final userObj = _stateManager.getGlobalState<Map<String, dynamic>>('user');
          final uid = userObj?['id']?.toString();
          analytics.logAuthEvent('user_authenticated', {
            if (uid != null) 'userId': uid,
            'loginMethod': 'email',
          });
          // Honor onSuccess if provided, otherwise default to /home
          if (config.onSuccess != null) {
            await execute(context, config.onSuccess!, {'response': {'ok': true}});
          } else {
            final switched = NavigationBridge.switchTo('/home');
            if (!switched) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        } else {
          await _handleShowError(
            context,
            ActionConfig(action: 'showError', params: {
              'message': 'Invalid email or password',
            }),
          );
          analytics.logAuthEvent('login_failed', {
            'reason': 'invalid_credentials',
          });
        }
        // For auth login, skip generic API call and summary dialog
        return;
      }

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
            title: Text(
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

  static Future<void> _handleUndo(ActionConfig config) async {
    final key = config.key ?? config.params?['key']?.toString();
    if (key == null) return;
    await _stateManager.undoState(key);
  }

  static Future<void> _handleRedo(ActionConfig config) async {
    final key = config.key ?? config.params?['key']?.toString();
    if (key == null) return;
    await _stateManager.redoState(key);
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
