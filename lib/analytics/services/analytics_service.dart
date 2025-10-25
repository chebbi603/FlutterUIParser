import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tracking_event.dart';

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

  /// Configure backend URL (optional)
  void configure({String? backendUrl}) {
    this.backendUrl = backendUrl;
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
    _applyLocalTagging(event);
    events.add(event);
    notifyListeners();
    if (kDebugMode) {
      final type = event.type.toString().split('.').last;
      print('📊 Tracked: $type (component=${event.componentId}, page=${event.pageId}, tag=${event.data['tag']})');
    }
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
      sessionId: 'default',
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
      sessionId: 'default',
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
      sessionId: 'default',
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

    final payload = jsonEncode(
      events.map((e) => _formatEventForBackend(e)).toList(),
    );

    try {
      final res = await http.post(
        Uri.parse(backendUrl!),
        headers: {
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (kDebugMode) print('🚀 Flushed ${events.length} events to backend');
        events.clear();
        notifyListeners();
      } else {
        if (kDebugMode) print('❌ Flush failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Flush error: $e');
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
    final typeStr = e.type.toString().split('.').last;
    final out = <String, dynamic>{
      'timestamp': e.timestamp.millisecondsSinceEpoch,
      'componentId': e.componentId ?? 'unknown',
      'eventType': typeStr,
    };
    // Optional tags
    if (e.data.containsKey('tag')) out['tag'] = e.data['tag'];
    if (e.data.containsKey('repeatCount')) out['repeatCount'] = e.data['repeatCount'];
    // Form submit result
    if (e.type == TrackingEventType.formSubmit) {
      out['result'] = (e.data['result'] ?? 'success').toString();
      if (e.data.containsKey('error')) out['error'] = e.data['error'];
    }
    return out;
  }

  String _generateEventId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1000);
    return 'evt_${ts}_$rand';
  }
}