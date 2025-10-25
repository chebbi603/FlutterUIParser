import 'dart:convert';
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
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<dynamic> read(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  @override
  Future<void> write(String key, dynamic value) async {
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
  }

  @override
  Future<void> delete(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<Map<String, dynamic>> readAll({String? prefix}) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final Map<String, dynamic> result = {};
    final keys = prefs.getKeys().where(
      (k) => prefix == null || k.startsWith(prefix),
    );
    for (final key in keys) {
      result[key] = prefs.get(key);
    }
    return result;
  }

  @override
  Future<void> clearAll({String? prefix}) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (prefix == null) {
      await prefs.clear();
    } else {
      final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
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
  }

  @override
  Future<void> write(String key, dynamic value) async {
    if (value is String) {
      await _storage.write(key: key, value: value);
    } else if (value is bool || value is int || value is double) {
      await _storage.write(key: key, value: value.toString());
    } else {
      await _storage.write(key: key, value: jsonEncode(value));
    }
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<Map<String, dynamic>> readAll({String? prefix}) async {
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
  }

  @override
  Future<void> clearAll({String? prefix}) async {
    if (prefix == null) {
      await _storage.deleteAll();
    } else {
      final all = await _storage.readAll();
      for (final key in all.keys.where((k) => k.startsWith(prefix))) {
        await _storage.delete(key: key);
      }
    }
  }
}
