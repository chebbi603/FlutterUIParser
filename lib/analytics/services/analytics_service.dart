import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tracking_event.dart';
import '../../providers/contract_provider.dart';
import '../../state/state_manager.dart';

/// Minimal AnalyticsService for Thesis PoC
/// - Keeps an in-memory list of events
/// - Provides simple `track()` and `flush()`
/// - Maintains a lightweight `trackComponentInteraction()` for compatibility
class AnalyticsService extends ChangeNotifier {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// In-memory event store
  final List<TrackingEvent> events = [];

  /// Optional backend endpoint to POST batches to
  String? backendUrl;
  String? wsUrl;
  int batchSize = 50;
  int flushIntervalMs = 5000;

  // --- Contract & Auth context ---
  ContractProvider? _contractProvider;
  EnhancedStateManager? _stateManager;

  /// Attach ContractProvider for contract metadata attribution
  void attachContractProvider(ContractProvider provider) {
    _contractProvider = provider;
  }

  /// Attach EnhancedStateManager to read current user id from global state
  void attachStateManager(EnhancedStateManager manager) {
    _stateManager = manager;
  }

  // --- Tagging configuration (defaults) ---
  int rageClickThreshold = 3; // clicks
  int rageClickWindowMs = 1000; // within 1s
  int rapidRepeatThreshold = 3; // actions
  int rapidRepeatWindowMs = 2000; // within 2s (generic)
  int formRepeatWindowMs = 10000; // within 10s (form submits)
  int formFailWindowMs = 10000; // link error to submit within 10s

  // --- Recent event windows ---
  final Map<String, List<int>> _recentTapMsByComponent = {};
  final Map<String, List<int>> _recentActionMsByKey = {};
  final Map<String, int> _lastSubmitTsByComponent = {};
  final Map<String, TrackingEvent> _lastSubmitByComponent = {};

  /// Configure backend URL and optional batch settings
  void configure({String? backendUrl, String? wsUrl, int? batchSize, int? flushIntervalMs}) {
    this.backendUrl = backendUrl;
    this.wsUrl = wsUrl;
    if (batchSize != null && batchSize > 0) this.batchSize = batchSize;
    if (flushIntervalMs != null && flushIntervalMs > 0) this.flushIntervalMs = flushIntervalMs;
  }

  /// Optional: update tagging thresholds
  void updateTaggingConfig({
    int? rageThreshold,
    int? rageWindowMs,
    int? repeatThreshold,
    int? repeatWindowMs,
    int? formRepeatWindowMs,
    int? formFailWindowMs,
  }) {
    if (rageThreshold != null) rageClickThreshold = rageThreshold;
    if (rageWindowMs != null) rageClickWindowMs = rageWindowMs;
    if (repeatThreshold != null) rapidRepeatThreshold = repeatThreshold;
    if (repeatWindowMs != null) rapidRepeatWindowMs = repeatWindowMs;
    if (formRepeatWindowMs != null) this.formRepeatWindowMs = formRepeatWindowMs;
    if (formFailWindowMs != null) this.formFailWindowMs = formFailWindowMs;
  }

  /// Add a tracking event to the in-memory list
  void track(TrackingEvent event) {
    // Determine page scope (public/authenticated) and attach contract metadata
    try {
      final scope = _determinePageScope(event.pageId);
      event.data['pageScope'] = scope;

      final ctEnum = _contractProvider?.contractSource;
      if (ctEnum != null) {
        event.data.putIfAbsent('contractType', () => ctEnum.toString());
      }
      event.data.putIfAbsent('contractVersion', () => _contractProvider?.contractVersion ?? 'unknown');
      event.data.putIfAbsent('isPersonalized', () => _contractProvider?.isPersonalized ?? false);
    } catch (_) {
      // Safe fallthrough: do not block tracking on scope computation errors
      event.data['pageScope'] ??= 'public';
    }
    _applyLocalTagging(event);
    events.add(event);
    notifyListeners();
    if (kDebugMode) {
      final type = event.type.toString().split('.').last;
      final tag = event.data['tag'];
      final ct = _contractProvider?.contractSource?.toString().split('.').last ?? 'unknown';
      final cv = _contractProvider?.contractVersion ?? 'unknown';
      final ip = _contractProvider?.isPersonalized ?? false;
      final scope = event.data['pageScope'];
      final userObj = _stateManager?.getGlobalState<Map<String, dynamic>>('user');
      final currentUserId = userObj?['id']?.toString();
      print('📊 Tracked: $type (component=${event.componentId}, page=${event.pageId}, scope=$scope, tag=$tag, contractType=$ct, version=$cv, personalized=$ip, user=$currentUserId)');
    }
  }

  /// Log authentication-related events with standardized payload
  /// eventType: 'user_authenticated', 'logout', 'login_failed', 'token_refresh_failed',
  /// as well as baseline page views: 'landing_page_viewed', 'login_page_viewed'
  void logAuthEvent(String eventType, Map<String, dynamic> data) {
    final sessionId = _getSessionIdFromState();
    final now = DateTime.now();
    final event = TrackingEvent(
      id: _generateEventId(),
      type: TrackingEventType.custom,
      timestamp: now,
      sessionId: sessionId,
      pageId: 'auth',
      data: {
        'eventType': eventType,
        'timestampIso': now.toIso8601String(),
        // Explicit page scope for auth flow metrics
        'pageScope': eventType.endsWith('_viewed') ? 'public' : 'auth',
        ...data,
      },
      context: {},
    );
    track(event);
  }

  /// Compatibility helper used by existing widgets
  Future<void> trackComponentInteraction({
    required String componentId,
    required String componentType,
    required TrackingEventType eventType,
    String? pageId,
    Map<String, dynamic>? data,
    Duration? duration,
  }) async {
    final event = TrackingEvent(
      id: _generateEventId(),
      type: eventType,
      timestamp: DateTime.now(),
      sessionId: _getSessionIdFromState(),
      componentId: componentId,
      componentType: componentType,
      pageId: pageId,
      data: data ?? {},
      context: {},
      duration: duration,
    );
    track(event);
  }

  /// Optional page navigation tracker (kept minimal for compatibility)
  Future<void> trackPageNavigation({
    required String pageId,
    required TrackingEventType eventType,
  }) async {
    final event = TrackingEvent(
      id: _generateEventId(),
      type: eventType,
      timestamp: DateTime.now(),
      sessionId: _getSessionIdFromState(),
      pageId: pageId,
      context: {},
    );
    track(event);
  }

  /// Optional error tracker (kept minimal)
  Future<void> trackError({
    required String errorMessage,
    String? componentId,
    String? pageId,
    Map<String, dynamic>? errorData,
  }) async {
    final event = TrackingEvent(
      id: _generateEventId(),
      type: TrackingEventType.error,
      timestamp: DateTime.now(),
      sessionId: _getSessionIdFromState(),
      componentId: componentId,
      pageId: pageId,
      errorMessage: errorMessage,
      data: errorData ?? {},
      context: {},
    );
    track(event);
  }

  /// Send all accumulated events as a JSON array to `backendUrl`
  Future<void> flush() async {
    if (events.isEmpty) {
      if (kDebugMode) print('📦 No events to flush');
      return;
    }
    if (backendUrl == null || backendUrl!.isEmpty) {
      if (kDebugMode) print('⚠️ No backendUrl configured; keeping ${events.length} events in memory');
      return;
    }

    // Flush in batches to avoid oversized payloads
    final all = events.map((e) => _formatEventForBackend(e)).toList();
    // Validate presence of contract metadata before sending (now inside data)
    final missingMeta = all.where((m) {
      final data = (m['data'] as Map<String, dynamic>?) ?? const {};
      return !data.containsKey('contractType') ||
          !data.containsKey('contractVersion') ||
          !data.containsKey('isPersonalized');
    });
    if (missingMeta.isNotEmpty && kDebugMode) {
      print('⚠️ Analytics flush: ${missingMeta.length} events missing contract metadata. Ensure AnalyticsService is attached to ContractProvider.');
    }
    int sent = 0;
    while (sent < all.length) {
      final chunk = all.sublist(sent, (sent + batchSize) > all.length ? all.length : (sent + batchSize));
      final payload = jsonEncode({'events': chunk});
      try {
        // Attach Authorization header when token available
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };
        try {
          final token = _stateManager?.getGlobalState<String>('authToken');
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        final res = await http.post(
          Uri.parse(backendUrl!),
          headers: headers,
          body: payload,
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          sent += chunk.length;
        } else if (res.statusCode == 401) {
          if (kDebugMode) print('❌ Analytics flush unauthorized (401).');
          final hasAuthedEvents = chunk.any((ev) {
            final data = (ev['data'] as Map<String, dynamic>?) ?? const {};
            return data['userId'] != null;
          });
          if (hasAuthedEvents) {
            if (kDebugMode) print('🧹 Clearing event queue due to auth failure for authenticated events');
            events.clear();
            notifyListeners();
          }
          break; // stop on auth failure
        } else {
          if (kDebugMode) print('❌ Flush failed: ${res.statusCode} ${res.body}');
          break; // stop on failure
        }
      } catch (e) {
        if (kDebugMode) print('❌ Flush error: $e');
        break;
      }
    }
    if (sent > 0) {
      if (kDebugMode) print('🚀 Flushed $sent/${all.length} events to backend');
      events.removeRange(0, sent);
      notifyListeners();
    }
  }

  /// Flush only baseline public-scope events for aggregate analysis
  Future<void> flushPublicBaseline() async {
    if (events.isEmpty) {
      if (kDebugMode) print('📦 No events to flush (public baseline)');
      return;
    }
    if (backendUrl == null || backendUrl!.isEmpty) {
      if (kDebugMode) print('⚠️ No backendUrl configured; keeping ${events.length} events in memory');
      return;
    }
    final formatted = events.map((e) => _formatEventForBackend(e)).toList();
    final publicOnly = formatted.where((m) {
      final data = (m['data'] as Map<String, dynamic>?) ?? const {};
      return (data['pageScope'] ?? 'public') == 'public';
    }).toList();
    if (publicOnly.isEmpty) {
      if (kDebugMode) print('ℹ️ No public-scope events to flush');
      return;
    }
    try {
      final headers = <String, String>{ 'Content-Type': 'application/json' };
      try {
        final token = _stateManager?.getGlobalState<String>('authToken');
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
      final res = await http.post(
        Uri.parse(backendUrl!),
        headers: headers,
        body: jsonEncode({'events': publicOnly}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (kDebugMode) print('🚀 Flushed ${publicOnly.length} public baseline events');
        // Remove flushed public events from queue
        _removeFlushed(publicOnly);
        notifyListeners();
      } else {
        if (kDebugMode) print('❌ Public baseline flush failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Public baseline flush error: $e');
    }
  }

  // --- Internal helpers ---

  void _applyLocalTagging(TrackingEvent event) {
    final ts = event.timestamp.millisecondsSinceEpoch;

    // Rage click detection (3+ taps in 1s on same component)
    if (event.type == TrackingEventType.tap && event.componentId != null) {
      final cid = event.componentId!;
      final list = _pruneAndAdd(
        _recentTapMsByComponent[cid] ?? <int>[],
        ts,
        rageClickWindowMs,
      );
      _recentTapMsByComponent[cid] = list;
      if (list.length >= rageClickThreshold) {
        event.data['tag'] = 'rage_click';
        event.data['repeatCount'] = list.length;
      }
    }

    // Rapid repeat detection (same action repeated within short window)
    if (event.componentId != null) {
      final cid = event.componentId!;
      final typeStr = event.type.toString().split('.').last;
      final key = '$cid:$typeStr';
      final window = event.type == TrackingEventType.formSubmit
          ? formRepeatWindowMs
          : rapidRepeatWindowMs;
      final list = _pruneAndAdd(
        _recentActionMsByKey[key] ?? <int>[],
        ts,
        window,
      );
      _recentActionMsByKey[key] = list;
      if (list.length >= rapidRepeatThreshold) {
        event.data['tag'] ??= 'rapid_repeat';
        event.data['repeatCount'] = list.length;
      }
    }

    // Form submit result tagging
    if (event.type == TrackingEventType.formSubmit && event.componentId != null) {
      final cid = event.componentId!;
      event.data['result'] ??= 'success';
      _lastSubmitTsByComponent[cid] = ts;
      _lastSubmitByComponent[cid] = event;
    }

    // Link error events to most recent submit for same component within window
    if (event.type == TrackingEventType.error && event.componentId != null) {
      final cid = event.componentId!;
      final lastTs = _lastSubmitTsByComponent[cid];
      if (lastTs != null && (ts - lastTs) <= formFailWindowMs) {
        final submitEvent = _lastSubmitByComponent[cid];
        if (submitEvent != null) {
          submitEvent.data['result'] = 'fail';
          final msg = event.errorMessage;
          if (msg != null && msg.isNotEmpty) {
            submitEvent.data['error'] = msg;
          } else if (event.data.containsKey('error')) {
            submitEvent.data['error'] = event.data['error'];
          }
        }
      }
    }
  }

  List<int> _pruneAndAdd(List<int> list, int nowMs, int windowMs) {
    final pruned = list.where((t) => (nowMs - t) <= windowMs).toList();
    pruned.add(nowMs);
    return pruned;
  }

  Map<String, dynamic> _formatEventForBackend(TrackingEvent e) {
    final userObj = _stateManager?.getGlobalState<Map<String, dynamic>>('user');
    final currentUserId = userObj?['id']?.toString();
    final dto = <String, dynamic>{
      'timestamp': e.timestamp.toIso8601String(),
      'componentId': e.componentId ?? 'unknown',
      'eventType': _mapEventTypeForBackend(e.type),
    };
    if (e.pageId != null && e.pageId!.isNotEmpty) {
      dto['page'] = e.pageId;
    }
    // Only include a valid sessionId (24-hex) to avoid server errors
    final sid = _getSessionIdFromState();
    if (sid != 'default' && _isValidObjectId(sid)) {
      dto['sessionId'] = sid;
    }
    // Extra analytics metadata moved under `data`
    final data = <String, dynamic>{
      'pageScope': e.data['pageScope'] ?? _determinePageScope(e.pageId),
      'contractType': _contractProvider?.contractSource?.toString().split('.').last ?? 'unknown',
      'contractVersion': _contractProvider?.contractVersion ?? 'unknown',
      'isPersonalized': _contractProvider?.isPersonalized ?? false,
    };
    if (currentUserId != null) data['userId'] = currentUserId;
    if (e.data.containsKey('tag')) data['tag'] = e.data['tag'];
    if (e.data.containsKey('repeatCount')) data['repeatCount'] = e.data['repeatCount'];
    if (e.type == TrackingEventType.formSubmit) {
      data['result'] = (e.data['result'] ?? 'success').toString();
      if (e.data.containsKey('error')) data['error'] = e.data['error'];
    }
    // Attach explicit error message if present
    if (e.errorMessage != null && e.errorMessage!.isNotEmpty) {
      data['message'] = e.errorMessage;
    }
    dto['data'] = data;
    return dto;
  }

  String _getSessionIdFromState() {
    try {
      final sid = _stateManager?.getGlobalState<String>('sessionId');
      if (sid != null && sid.isNotEmpty) return sid;
    } catch (_) {}
    return 'default';
  }

  /// Remove flushed events from the in-memory queue by matching signatures
  void _removeFlushed(List<Map<String, dynamic>> flushedBatch) {
    final signatures = flushedBatch.map((m) {
      final ts = m['timestamp'];
      final sid = m['sessionId'];
      final et = m['eventType'];
      final cid = m['componentId'];
      final scope = (m['data'] as Map<String, dynamic>?)?['pageScope'];
      return '$ts|$sid|$et|$cid|$scope';
    }).toSet();
    events.removeWhere((e) {
      final fm = _formatEventForBackend(e);
      final d = (fm['data'] as Map<String, dynamic>?) ?? const {};
      final sig = '${fm['timestamp']}|${fm['sessionId']}|${fm['eventType']}|${fm['componentId']}|${d['pageScope']}';
      return signatures.contains(sig);
    });
  }

  /// Determine if a page is public (shared) or authenticated (personalized)
  String _determinePageScope(String? pageId) {
    try {
      if (pageId == null || pageId.isEmpty) return 'public';

      // Simple hardcoded list for initial implementation; can be made dynamic later
      const hardcodedAuthPages = {
        'profile', 'settings', 'dashboard', 'account'
      };
      if (hardcodedAuthPages.contains(pageId)) return 'authenticated';

      // Try to infer from contract routes' auth requirements
      final contract = _contractProvider?.contract;
      final Map<String, dynamic>? pagesUi =
          (contract is Map<String, dynamic>) && (contract['pagesUI'] is Map<String, dynamic>)
              ? contract['pagesUI'] as Map<String, dynamic>
              : null;
      final Map<String, dynamic>? routes =
          pagesUi != null && pagesUi['routes'] is Map<String, dynamic>
              ? pagesUi['routes'] as Map<String, dynamic>
              : null;
      if (routes != null) {
        for (final entry in routes.entries) {
          final value = entry.value;
          if (value is Map<String, dynamic>) {
            final rid = value['pageId']?.toString();
            if (rid == pageId) {
              final authVal = value['auth'];
              if (authVal == true) return 'authenticated';
              if (authVal is String) {
                final v = authVal.toLowerCase();
                if (v == 'required' || v == 'true' || v == 'auth' || v == 'authenticated') {
                  return 'authenticated';
                }
              }
              return 'public';
            }
          }
        }
      }
    } catch (_) {
      // Fallthrough to public
    }
    return 'public';
  }

  String _generateEventId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1000);
    return 'evt_${ts}_$rand';
  }

  String _mapEventTypeForBackend(TrackingEventType type) {
    switch (type) {
      case TrackingEventType.tap:
        return 'tap';
      case TrackingEventType.scroll:
      case TrackingEventType.swipe:
      case TrackingEventType.componentRender:
      case TrackingEventType.apiCall:
        return 'view';
      case TrackingEventType.focus:
      case TrackingEventType.blur:
      case TrackingEventType.input:
      case TrackingEventType.stateChange:
      case TrackingEventType.formSubmit:
        return 'input';
      case TrackingEventType.pageEnter:
      case TrackingEventType.pageExit:
      case TrackingEventType.routeChange:
      case TrackingEventType.networkChange:
      case TrackingEventType.appBackground:
      case TrackingEventType.appForeground:
        return 'navigate';
      case TrackingEventType.validationError:
      case TrackingEventType.error:
        return 'error';
      case TrackingEventType.custom:
      default:
        return 'tap';
    }
  }

  bool _isValidObjectId(String id) {
    final hex24 = RegExp(r'^[0-9a-fA-F]{24}$');
    return hex24.hasMatch(id);
  }
}