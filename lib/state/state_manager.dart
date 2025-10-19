import 'package:flutter/foundation.dart';
import '../models/config_models.dart';
import '../persistence/state_persistence.dart';
import '../utils/parsing_utils.dart';
import '../engine/graph_engine.dart';

/// Enhanced state manager with persistence and scoped state
class EnhancedStateManager extends ChangeNotifier {
  static final EnhancedStateManager _instance =
      EnhancedStateManager._internal();
  factory EnhancedStateManager() => _instance;
  EnhancedStateManager._internal();

  final Map<String, dynamic> _globalState = {};
  final Map<String, Map<String, dynamic>> _pageState = {};
  final Map<String, dynamic> _sessionState = {};
  final Map<String, dynamic> _memoryState = {};

  // Undo/redo stacks per state path
  final Map<String, List<dynamic>> _history = {};
  final Map<String, List<dynamic>> _redo = {};

  StateConfig? _config;
  bool _hydrated = false;

  final StatePersistence _localPersistence = SharedPrefsPersistence();
  final StatePersistence _securePersistence = SecureStoragePersistence();

  /// Initialize with state configuration
  Future<void> initialize(StateConfig config) async {
    _config = config;
    await _initPersistence();
    await _hydrateFromPersistence();
    _initializeDefaults();
  }

  void _initializeDefaults() {
    if (_config == null) return;

    // Initialize global defaults
    for (final entry in _config!.global.entries) {
      final key = entry.key;
      final fieldConfig = entry.value;

      if (!_globalState.containsKey(key) && fieldConfig.defaultValue != null) {
        _globalState[key] = _castValue(fieldConfig.type, fieldConfig.defaultValue);
      }
    }

    // Initialize page defaults
    for (final pageEntry in _config!.pages.entries) {
      final pageId = pageEntry.key;
      final pageFields = pageEntry.value;

      _pageState[pageId] ??= {};

      for (final fieldEntry in pageFields.entries) {
        final key = fieldEntry.key;
        final fieldConfig = fieldEntry.value;

        if (!_pageState[pageId]!.containsKey(key) &&
            fieldConfig.defaultValue != null) {
          _pageState[pageId]![key] = _castValue(fieldConfig.type, fieldConfig.defaultValue);
        }
      }
    }
  }

  Future<void> _initPersistence() async {
    await _localPersistence.init();
    await _securePersistence.init();
  }

  Future<void> _hydrateFromPersistence() async {
    if (_config == null || _hydrated) return;
    for (final entry in _config!.global.entries) {
      final key = entry.key;
      final field = entry.value;
      final persistedKey = _globalStorageKey(key);
      final persistedValue = await _readByPolicy(field.persistence, persistedKey);
      if (persistedValue != null) {
        _globalState[key] = _castValue(field.type, persistedValue);
      }
    }
    for (final pageEntry in _config!.pages.entries) {
      final pageId = pageEntry.key;
      _pageState[pageId] ??= {};
      final fields = pageEntry.value;
      for (final fieldEntry in fields.entries) {
        final key = fieldEntry.key;
        final field = fieldEntry.value;
        final persistedKey = _pageStorageKey(pageId, key);
        final persistedValue = await _readByPolicy(field.persistence, persistedKey);
        if (persistedValue != null) {
          _pageState[pageId]![key] = _castValue(field.type, persistedValue);
        }
      }
    }
    _hydrated = true;
  }

  Future<dynamic> _readByPolicy(String? persistence, String storageKey) async {
    switch (persistence) {
      case 'secure':
        return await _securePersistence.read(storageKey);
      case 'local':
      case 'device':
        return await _localPersistence.read(storageKey);
      case 'session':
      case 'memory':
      case null:
      default:
        return null;
    }
  }

  Future<void> _writeByPolicy(String? persistence, String storageKey, dynamic value) async {
    switch (persistence) {
      case 'secure':
        await _securePersistence.write(storageKey, value);
        break;
      case 'local':
      case 'device':
        await _localPersistence.write(storageKey, value);
        break;
      case 'session':
      case 'memory':
      case null:
      default:
        break;
    }
  }

  String _globalStorageKey(String key) => 'state:global:$key';
  String _pageStorageKey(String pageId, String key) => 'state:page:$pageId:$key';

  dynamic _castValue(String type, dynamic value) {
    switch (type) {
      case 'boolean':
        return ParsingUtils.safeToBool(value) ?? value;
      case 'number':
      case 'int':
      case 'double':
        return ParsingUtils.safeToDouble(value) ?? value;
      case 'string':
        return value?.toString();
      default:
        return value;
    }
  }

  /// Get global state value
  T? getGlobalState<T>(String key) {
    return _globalState[key] as T?;
  }

  /// Set global state value
  Future<void> setGlobalState(String key, dynamic value) async {
    // Push previous value to history
    final prev = _globalState.containsKey(key) ? _globalState[key] : null;
    _history.putIfAbsent(key, () => <dynamic>[]).add(prev);
    _redo[key]?.clear();

    _globalState[key] = value;
    final fieldConfig = _config?.global[key];
    if (fieldConfig != null) {
      await _writeByPolicy(fieldConfig.persistence, _globalStorageKey(key), value);
    }
    GraphEngine().notifyStateChange(key);
    notifyListeners();
  }

  /// Get page state value
  T? getPageState<T>(String pageId, String key) {
    return _pageState[pageId]?[key] as T?;
  }

  /// Set page state value
  Future<void> setPageState(String pageId, String key, dynamic value) async {
    _pageState[pageId] ??= {};
    // Push previous value to history with namespaced path
    final path = '$pageId.$key';
    final prev = _pageState[pageId]!.containsKey(key) ? _pageState[pageId]![key] : null;
    _history.putIfAbsent(path, () => <dynamic>[]).add(prev);
    _redo[path]?.clear();

    _pageState[pageId]![key] = value;
    final fieldConfig = _config?.pages[pageId]?[key];
    if (fieldConfig != null) {
      await _writeByPolicy(fieldConfig.persistence, _pageStorageKey(pageId, key), value);
    }
    GraphEngine().notifyStateChange(path);
    notifyListeners();
  }

  /// Get state value with automatic scope resolution
  T? getState<T>(String path) {
    final parts = path.split('.');

    if (parts.length == 1) {
      // Global state
      return getGlobalState<T>(parts[0]);
    } else if (parts.length == 2) {
      // Page state
      return getPageState<T>(parts[0], parts[1]);
    }

    return null;
  }

  /// Set state value with automatic scope resolution
  Future<void> setState(String path, dynamic value) async {
    final parts = path.split('.');

    if (parts.length == 1) {
      // Global state
      await setGlobalState(parts[0], value);
    } else if (parts.length == 2) {
      // Page state
      await setPageState(parts[0], parts[1], value);
    }
  }

  /// Get session state (memory only)
  T? getSessionState<T>(String key) {
    return _sessionState[key] as T?;
  }

  /// Set session state (memory only)
  void setSessionState(String key, dynamic value) {
    _sessionState[key] = value;
    GraphEngine().notifyStateChange('session.$key');
    notifyListeners();
  }

  /// Get memory state (temporary)
  T? getMemoryState<T>(String key) {
    return _memoryState[key] as T?;
  }

  /// Set memory state (temporary)
  void setMemoryState(String key, dynamic value) {
    _memoryState[key] = value;
    GraphEngine().notifyStateChange('memory.$key');
    notifyListeners();
  }

  /// Clear all state
  Future<void> clearAll() async {
    _globalState.clear();
    _pageState.clear();
    _sessionState.clear();
    _memoryState.clear();
    await _localPersistence.clearAll(prefix: 'state:');
    await _securePersistence.clearAll(prefix: 'state:');
    notifyListeners();
  }

  /// Clear page state
  Future<void> clearPageState(String pageId) async {
    _pageState.remove(pageId);
    await _localPersistence.clearAll(prefix: 'state:page:$pageId:');
    await _securePersistence.clearAll(prefix: 'state:page:$pageId:');
    notifyListeners();
  }

  /// Get all global state
  Map<String, dynamic> getAllGlobalState() {
    return Map.from(_globalState);
  }

  /// Get all page state for a specific page
  Map<String, dynamic> getAllPageState(String pageId) {
    return Map.from(_pageState[pageId] ?? {});
  }

  /// Undo the last change for a state path (global or page)
  Future<void> undoState(String path) async {
    final stack = _history[path];
    if (stack == null || stack.isEmpty) return;
    final prev = stack.removeLast();
    // Keep current value for redo
    final current = getState(path);
    _redo.putIfAbsent(path, () => <dynamic>[]).add(current);
    await setState(path, prev);
  }

  /// Redo the last undone change for a state path
  Future<void> redoState(String path) async {
    final stack = _redo[path];
    if (stack == null || stack.isEmpty) return;
    final next = stack.removeLast();
    // Push current to history
    final current = getState(path);
    _history.putIfAbsent(path, () => <dynamic>[]).add(current);
    await setState(path, next);
  }
}
