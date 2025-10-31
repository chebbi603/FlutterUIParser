import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/config_models.dart';

class ContractCache {
  final CanonicalContract contract;
  final String? version;
  final DateTime timestamp;
  final bool isExpired;

  ContractCache({
    required this.contract,
    required this.version,
    required this.timestamp,
    required this.isExpired,
  });
}

class ContractLoader {
  static const String _cacheKeyJson = 'contract:cache:json';
  static const String _cacheKeyVersion = 'contract:cache:version';
  static const String _cacheKeyTimestamp = 'contract:cache:timestamp';

  static const Duration cacheTtl = Duration(hours: 24);
  static const Duration defaultTimeout = Duration(seconds: 8);
  static const Duration retryDelay = Duration(seconds: 60);
  static const Duration pollInterval = Duration(minutes: 10);

  Timer? _retryTimer;
  Timer? _pollTimer;

  Future<ContractCache?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKeyJson);
      final version = prefs.getString(_cacheKeyVersion);
      final tsString = prefs.getString(_cacheKeyTimestamp);
      if (jsonString == null || tsString == null) return null;
      final ts = DateTime.tryParse(tsString) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final isExpired = DateTime.now().difference(ts) > cacheTtl;

      final dynamic raw = json.decode(jsonString);
      if (!_isValidStructure(raw)) return null;
      final contract = CanonicalContract.fromJson(Map<String, dynamic>.from(raw));
      return ContractCache(
        contract: contract,
        version: version,
        timestamp: ts,
        isExpired: isExpired,
      );
    } catch (e) {
      debugPrint('Failed to load contract from cache: $e');
      return null;
    }
  }

  Future<CanonicalContract> loadFromAssets() async {
    String? contents;
    try {
      contents = await rootBundle.loadString('assets/contracts/canonical.json');
    } catch (_) {
      // Fallback to legacy path for demo compatibility
      contents = await rootBundle.loadString('assets/canonical_contract.json');
    }

    final dynamic raw = json.decode(contents);
    if (!_isValidStructure(raw)) {
      throw Exception('Canonical contract validation failed');
    }
    return CanonicalContract.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<CanonicalContract?> fetchFromApi({
    required String baseUrl,
    required String userId,
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse(_joinPaths(baseUrl, '/users/$userId/contract'));
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
          )
          .timeout(defaultTimeout);

      if (response.statusCode != 200) {
        debugPrint('Contract API failed: ${response.statusCode} ${response.body}');
        return null;
      }

      final bodyString = response.body;
      final dynamic raw = json.decode(bodyString);
      if (!_isValidStructure(raw)) {
        debugPrint('Contract API returned malformed structure');
        return null;
      }
      final contract = CanonicalContract.fromJson(Map<String, dynamic>.from(raw));
      final version = _extractVersion(raw);
      await _saveCache(bodyString, version);
      return contract;
    } catch (e) {
      debugPrint('Contract API error: $e');
      return null;
    }
  }

  /// Fetch the latest canonical (public) contract from backend without auth.
  /// Endpoint: GET `${baseUrl}/contracts/canonical`
  Future<CanonicalContract?> fetchCanonicalFromApi({
    required String baseUrl,
  }) async {
    try {
      Future<http.Response> doGet(String path) {
        final uri = Uri.parse(_joinPaths(baseUrl, path));
        return http
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
              },
            )
            .timeout(defaultTimeout);
      }

      // Try primary public endpoint first
      var response = await doGet('/contracts/canonical');
      if (response.statusCode == 401 || response.statusCode == 404) {
        // Fallback alias to avoid collisions with dynamic routes
        response = await doGet('/contracts/public/canonical');
      }
      if (response.statusCode != 200) {
        debugPrint('Canonical contract API failed: ${response.statusCode} ${response.body}');
        return null;
      }

      final dto = json.decode(response.body);
      if (dto is! Map) {
        debugPrint('Canonical contract API returned non-object payload');
        return null;
      }
      final dynamic raw = dto['json'];
      if (raw == null) {
        debugPrint('Canonical contract API missing json field');
        return null;
      }
      if (!_isValidStructure(raw)) {
        debugPrint('Canonical contract validation failed');
        return null;
      }
      final contract = CanonicalContract.fromJson(Map<String, dynamic>.from(raw as Map));
      final version = _extractVersion(dto) ?? _extractVersion(raw);
      await _saveCache(json.encode(raw), version);
      return contract;
    } catch (e) {
      debugPrint('Canonical contract API error: $e');
      return null;
    }
  }

  Future<void> _saveCache(String jsonString, String? version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKeyJson, jsonString);
    if (version != null) {
      await prefs.setString(_cacheKeyVersion, version);
    }
    await prefs.setString(_cacheKeyTimestamp, DateTime.now().toIso8601String());
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyJson);
    await prefs.remove(_cacheKeyVersion);
    await prefs.remove(_cacheKeyTimestamp);
  }

  void scheduleRetry(Future<void> Function() action) {
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, () async {
      try {
        await action();
      } catch (e) {
        debugPrint('Retry failed: $e');
      }
    });
  }

  void startPolling({
    required String baseUrl,
    required String userId,
    required String authToken,
    required String currentVersion,
    required void Function(CanonicalContract newContract) onUpdate,
  }) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) async {
      try {
        final latest = await fetchFromApi(
          baseUrl: baseUrl,
          userId: userId,
          authToken: authToken,
        );
        if (latest != null && latest.meta.version != currentVersion) {
          onUpdate(latest);
        }
      } catch (e) {
        debugPrint('Polling failed: $e');
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    _retryTimer?.cancel();
    _pollTimer?.cancel();
  }

  bool _isValidStructure(dynamic raw) {
    if (raw is! Map) return false;
    final pagesUI = raw['pagesUI'];
    if (pagesUI is! Map) return false;
    final pages = pagesUI['pages'];
    if (pages == null) return false;
    if (pages is Map && pages.isEmpty) return false;
    if (pages is List && pages.isEmpty) return false; // in case a list is used
    return true;
  }

  String? _extractVersion(dynamic raw) {
    try {
      final meta = (raw as Map)['meta'] as Map?;
      return meta?['version']?.toString();
    } catch (_) {
      return null;
    }
  }

  String _joinPaths(String base, String path) {
    if (base.endsWith('/') && path.startsWith('/')) {
      return base.substring(0, base.length - 1) + path;
    }
    if (!base.endsWith('/') && !path.startsWith('/')) {
      return '$base/$path';
    }
    return base + path;
  }
}