import 'package:flutter/foundation.dart';
import '../models/config_models.dart';

/// Middleware for actions: logging, analytics, permissions, loading states, etc.
abstract class ActionMiddleware {
  Future<void> before(ActionConfig config, Map<String, dynamic>? ctx) async {}
  Future<void> after(ActionConfig config, Map<String, dynamic>? ctx) async {}
  Future<void> onError(
    ActionConfig config,
    Object error,
    Map<String, dynamic>? ctx,
  ) async {}
}

class LoggingMiddleware extends ActionMiddleware {
  @override
  Future<void> before(ActionConfig config, Map<String, dynamic>? ctx) async {
    debugPrint('[action] start ${config.action} ctx=$ctx');
  }

  @override
  Future<void> after(ActionConfig config, Map<String, dynamic>? ctx) async {
    debugPrint('[action] end   ${config.action} ctx=$ctx');
  }

  @override
  Future<void> onError(
    ActionConfig config,
    Object error,
    Map<String, dynamic>? ctx,
  ) async {
    debugPrint('[action] error ${config.action}: $error');
  }
}

class ActionMiddlewarePipeline {
  static final ActionMiddlewarePipeline _instance =
      ActionMiddlewarePipeline._internal();
  factory ActionMiddlewarePipeline() => _instance;
  ActionMiddlewarePipeline._internal();

  final List<ActionMiddleware> _middlewares = [LoggingMiddleware()];

  Future<void> runBefore(ActionConfig config, Map<String, dynamic>? ctx) async {
    for (final m in _middlewares) {
      await m.before(config, ctx);
    }
  }

  Future<void> runAfter(ActionConfig config, Map<String, dynamic>? ctx) async {
    for (final m in _middlewares) {
      await m.after(config, ctx);
    }
  }

  Future<void> runOnError(
    ActionConfig config,
    Object error,
    Map<String, dynamic>? ctx,
  ) async {
    for (final m in _middlewares) {
      await m.onError(config, error, ctx);
    }
  }

  void use(ActionMiddleware middleware) {
    _middlewares.add(middleware);
  }
}
