import 'dart:async';

/// Simple event bus for pub/sub communication between components and systems.
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();

  Stream<T> on<T>() => _controller.stream.where((e) => e is T).cast<T>();

  void emit(dynamic event) => _controller.add(event);

  void dispose() => _controller.close();
}

/// Common events
class ActionStarted {
  final String action;
  final Map<String, dynamic>? context;
  ActionStarted(this.action, [this.context]);
}

class ActionCompleted {
  final String action;
  final Map<String, dynamic>? result;
  ActionCompleted(this.action, [this.result]);
}

class ActionFailed {
  final String action;
  final Object error;
  ActionFailed(this.action, this.error);
}
