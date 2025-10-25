import 'package:flutter/material.dart';
import '../models/tracking_event.dart';
import '../services/analytics_service.dart';
import 'dart:math';

/// Wrapper widget that adds minimal tracking to any child widget
class ComponentTracker extends StatefulWidget {
  /// Child widget to track
  final Widget child;

  /// Component ID for tracking
  final String componentId;

  /// Component type for tracking
  final String componentType;

  /// Page ID for tracking
  final String? pageId;

  /// Whether tracking is enabled
  final bool enabled;

  /// Additional tracking data
  final Map<String, dynamic> trackingData;

  /// Whether to track gestures automatically (tap only)
  final bool trackGestures;

  const ComponentTracker({
    super.key,
    required this.child,
    required this.componentId,
    required this.componentType,
    this.pageId,
    this.enabled = true,
    this.trackingData = const {},
    this.trackGestures = true,
  });

  @override
  State<ComponentTracker> createState() => _ComponentTrackerState();
}

class _ComponentTrackerState extends State<ComponentTracker> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    // Wrap with simple gesture tracking if enabled
    if (widget.trackGestures) {
      child = _wrapWithGestureTracking(child);
    }

    return child;
  }

  /// Wrap child with gesture tracking (tap only)
  Widget _wrapWithGestureTracking(Widget child) {
    return GestureDetector(
      onTap: () => _trackInteraction(TrackingEventType.tap),
      child: child,
    );
  }

  /// Track component interaction
  Future<void> _trackInteraction(
    TrackingEventType eventType, {
    Map<String, dynamic>? data,
    Duration? duration,
  }) async {
    if (!widget.enabled) return;

    final event = TrackingEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 32)}',
      type: eventType,
      timestamp: DateTime.now(),
      sessionId: 'default',
      componentId: widget.componentId,
      componentType: widget.componentType,
      pageId: widget.pageId,
      data: {
        ...widget.trackingData,
        ...?data,
      },
      context: {},
      duration: duration,
    );
    _analytics.track(event);
  }
}