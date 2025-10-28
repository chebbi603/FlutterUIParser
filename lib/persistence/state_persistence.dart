import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class StatePersistence {
  Future<void> init();
  Future<dynamic> read(String key);
  Future<void> write(String key, dynamic value);
  Future<void> delete(String key);
  Future<Map<String, dynamic>> readAll({String? prefix});
  Future<void> clearAll({String? prefix});
}

class SharedPrefsPersistence implements StatePersistence {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SharedPrefsPersistence.init error: $e');
      }
      _prefs = null; // fall back to null; reads will return null
    }
  }

  @override
  Future<dynamic> read(String key) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      return prefs.get(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SharedPrefsPersistence.read("$key") error: $e');
      }
      return null;
    }
  }

  @override
  Future<void> write(String key, dynamic value) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else {
        await prefs.setString(key, jsonEncode(value));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SharedPrefsPersistence.write("$key") error: $e');
      }
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SharedPrefsPersistence.delete("$key") error: $e');
      }
    }
  }

  @override
  Future<Map<String, dynamic>> readAll({String? prefix}) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final Map<String, dynamic> result = {};
      final keys = prefs.getKeys().where(
        (k) => prefix == null || k.startsWith(prefix),
      );
      for (final key in keys) {
        result[key] = prefs.get(key);
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SharedPrefsPersistence.readAll error: $e');
      }
      return {};
    }
  }

  @override
  Future<void> clearAll({String? prefix}) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (prefix == null) {
        await prefs.clear();
      } else {
        final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
        for (final key in keys) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SharedPrefsPersistence.clearAll error: $e');
      }
    }
  }
}

class SecureStoragePersistence implements StatePersistence {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> init() async {}

  @override
  Future<dynamic> read(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      try {
        return jsonDecode(raw);
      } catch (_) {
        if (raw == 'true' || raw == 'false') return raw == 'true';
        final intVal = int.tryParse(raw);
        if (intVal != null) return intVal;
        final doubleVal = double.tryParse(raw);
        if (doubleVal != null) return doubleVal;
        return raw;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStoragePersistence.read("$key") error: $e');
      }
      return null;
    }
  }

  @override
  Future<void> write(String key, dynamic value) async {
    try {
      if (value is String) {
        await _storage.write(key: key, value: value);
      } else if (value is bool || value is int || value is double) {
        await _storage.write(key: key, value: value.toString());
      } else {
        await _storage.write(key: key, value: jsonEncode(value));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStoragePersistence.write("$key") error: $e');
      }
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStoragePersistence.delete("$key") error: $e');
      }
    }
  }

  @override
  Future<Map<String, dynamic>> readAll({String? prefix}) async {
    try {
      final all = await _storage.readAll();
      final Map<String, dynamic> result = {};
      for (final entry in all.entries) {
        if (prefix == null || entry.key.startsWith(prefix)) {
          try {
            result[entry.key] = jsonDecode(entry.value);
          } catch (_) {
            result[entry.key] = entry.value;
          }
        }
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStoragePersistence.readAll error: $e');
      }
      return {};
    }
  }

  @override
  Future<void> clearAll({String? prefix}) async {
    try {
      if (prefix == null) {
        await _storage.deleteAll();
      } else {
        final all = await _storage.readAll();
        for (final key in all.keys.where((k) => k.startsWith(prefix))) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStoragePersistence.clearAll error: $e');
      }
    }
  }
}
