/// Types of events that can be tracked
enum TrackingEventType {
  // Interaction events
  tap,
  scroll,
  swipe,
  focus,
  blur,
  input,
  
  // Navigation events
  pageEnter,
  pageExit,
  routeChange,
  
  // State events
  stateChange,
  formSubmit,
  validationError,
  
  // Performance events
  componentRender,
  apiCall,
  error,
  
  // Context events
  networkChange,
  appBackground,
  appForeground,
  
  // Custom events
  custom,
}

/// Individual tracking event with rich context
class TrackingEvent {
  /// Unique event identifier
  final String id;
  
  /// Event type for categorization
  final TrackingEventType type;
  
  /// Timestamp when event occurred
  final DateTime timestamp;
  
  /// Component that triggered the event (if applicable)
  final String? componentId;
  
  /// Component type (button, textField, etc.)
  final String? componentType;
  
  /// Page where event occurred
  final String? pageId;
  
  /// Event-specific data payload
  final Map<String, dynamic> data;
  
  /// Rich context at time of event
  final Map<String, dynamic> context;
  
  /// Session identifier
  final String sessionId;
  
  /// User identifier (anonymized)
  final String? userId;
  
  /// Duration of the interaction (for performance events)
  final Duration? duration;
  
  /// Error information (for error events)
  final String? errorMessage;
  
  /// Previous event ID for sequence tracking
  final String? previousEventId;

  TrackingEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.sessionId,
    this.componentId,
    this.componentType,
    this.pageId,
    Map<String, dynamic>? data,
    Map<String, dynamic>? context,
    this.userId,
    this.duration,
    this.errorMessage,
    this.previousEventId,
  })  : data = data ?? <String, dynamic>{},
        context = context ?? <String, dynamic>{};

  /// Create event from JSON
  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      id: json['id'] as String,
      type: TrackingEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TrackingEventType.custom,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['sessionId'] as String,
      componentId: json['componentId'] as String?,
      componentType: json['componentType'] as String?,
      pageId: json['pageId'] as String?,
      data: (json['data'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{},
      context: (json['context'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['context'] as Map)
          : <String, dynamic>{},
      userId: json['userId'] as String?,
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      errorMessage: json['errorMessage'] as String?,
      previousEventId: json['previousEventId'] as String?,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      if (componentId != null) 'componentId': componentId,
      if (componentType != null) 'componentType': componentType,
      if (pageId != null) 'pageId': pageId,
      'data': data,
      'context': context,
      if (userId != null) 'userId': userId,
      if (duration != null) 'duration': duration!.inMilliseconds,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (previousEventId != null) 'previousEventId': previousEventId,
    };
  }

  /// Convert to LLM-friendly format with semantic meaning
  Map<String, dynamic> toLLMFormat() {
    return {
      'event_summary': _generateEventSummary(),
      'interaction_type': type.toString().split('.').last,
      'component_info': {
        'id': componentId,
        'type': componentType,
        'page': pageId,
      },
      'timing': {
        'timestamp': timestamp.toIso8601String(),
        'duration_ms': duration?.inMilliseconds,
      },
      'user_action': _describeUserAction(),
      'context_snapshot': _simplifyContext(),
      'metadata': {
        'session_id': sessionId,
        'user_id': userId,
        'sequence_position': previousEventId != null ? 'continuation' : 'start',
      },
    };
  }

  /// Generate human-readable event summary
  String _generateEventSummary() {
    switch (type) {
      case TrackingEventType.tap:
        return 'User tapped ${componentType ?? 'component'} ${componentId ?? 'unknown'}';
      case TrackingEventType.input:
        return 'User entered text in ${componentType ?? 'field'} ${componentId ?? 'unknown'}';
      case TrackingEventType.pageEnter:
        return 'User navigated to page $pageId';
      case TrackingEventType.formSubmit:
        return 'User submitted form on page $pageId';
      case TrackingEventType.error:
        return 'Error occurred: ${errorMessage ?? 'Unknown error'}';
      default:
        return 'User performed ${type.toString().split('.').last} action';
    }
  }

  /// Describe the user action in natural language
  String _describeUserAction() {
    final action = type.toString().split('.').last;
    final target = componentType ?? 'element';
    return '$action on $target';
  }

  /// Simplify context for LLM consumption
  Map<String, dynamic> _simplifyContext() {
    return {
      'page_state': context['pageState'] ?? {},
      'form_states': context['formStates'] ?? {},
      'network_status': context['networkStatus'] ?? 'unknown',
      'device_info': context['deviceInfo'] ?? {},
      'app_state': context['appState'] ?? {},
    };
  }

  @override
  String toString() {
    return 'TrackingEvent(id: $id, type: $type, componentId: $componentId, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackingEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}