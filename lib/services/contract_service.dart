import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// ContractService handles fetching the canonical contract JSON from the backend
/// with a robust fallback strategy and clear error logging.
///
/// - Primary endpoint: `GET {baseUrl}/contracts/canonical`
/// - Fallback endpoint: `GET {baseUrl}/contracts/public/canonical`
/// - Final fallback: load local asset `assets/canonical_contract.json`
///
/// The service enforces a 10-second timeout and sets `Accept: application/json`.
class ContractService {
  final String baseUrl;
  final http.Client _client;
  final Duration _timeout;

  ContractService({
    required this.baseUrl,
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  /// Fetch canonical contract as a JSON map.
  ///
  /// Returns the parsed map from backend when available, otherwise falls back
  /// to bundled asset `assets/canonical_contract.json`.
  Future<Map<String, dynamic>> fetchCanonicalContract() async {
    // 1) Try primary backend endpoint
    try {
      final primaryUrl = _buildUrl('/contracts/canonical');
      _log('Attempting primary endpoint: GET $primaryUrl');
      final response = await _client
          .get(primaryUrl, headers: _jsonHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _log('Primary endpoint succeeded (200)');
        return _parseJsonToMap(response.body, source: 'primary response');
      } else {
        _log('Primary endpoint non-200: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _log('Primary endpoint timed out: $e');
    } on FormatException catch (e) {
      _log('Primary endpoint returned malformed JSON: $e');
    } on http.ClientException catch (e) {
      _log('Primary endpoint client error: $e');
    } catch (e) {
      // Avoid importing dart:io for web compatibility; treat as generic network error.
      _log('Primary endpoint error: $e');
    }

    // 2) Fallback backend endpoint
    try {
      final fallbackUrl = _buildUrl('/contracts/public/canonical');
      _log('Attempting fallback endpoint: GET $fallbackUrl');
      final response = await _client
          .get(fallbackUrl, headers: _jsonHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _log('Fallback endpoint succeeded (200)');
        return _parseJsonToMap(response.body, source: 'fallback response');
      } else {
        _log('Fallback endpoint non-200: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _log('Fallback endpoint timed out: $e');
    } on FormatException catch (e) {
      _log('Fallback endpoint returned malformed JSON: $e');
    } on http.ClientException catch (e) {
      _log('Fallback endpoint client error: $e');
    } catch (e) {
      _log('Fallback endpoint error: $e');
    }

    // 3) Final fallback: local bundled asset
    try {
      _log('Loading local asset: assets/canonical_contract.json');
      final assetString = await rootBundle
          .loadString('assets/canonical_contract.json')
          .timeout(_timeout);
      final map = _parseAssetToMap(assetString);
      _log('Local asset loaded successfully');
      return map;
    } on TimeoutException catch (e) {
      _log('Asset load timed out: $e');
      rethrow;
    } on FormatException catch (e) {
      _log('Asset JSON malformed: $e');
      rethrow;
    } catch (e) {
      _log('Asset load error: $e');
      rethrow;
    }
  }

  Map<String, String> get _jsonHeaders => const {
        'Accept': 'application/json',
      };

  /// Build a properly joined URL from base and path.
  Uri _buildUrl(String path) {
    final base = baseUrl.trim();
    final normalized = path.startsWith('/') ? path : '/$path';
    final joined = base.endsWith('/') ? '${base.substring(0, base.length - 1)}$normalized' : '$base$normalized';
    return Uri.parse(joined);
  }

  /// Parse backend response body which may be either the canonical map directly
  /// or a wrapper object containing a `json` field with the canonical map.
  Map<String, dynamic> _parseJsonToMap(String body, {required String source}) {
    final dynamic decoded = json.decode(body);
    if (decoded is Map) {
      if (decoded.containsKey('json')) {
        final dynamic inner = decoded['json'];
        if (inner is Map) {
          return Map<String, dynamic>.from(inner as Map);
        } else {
          throw const FormatException('Wrapper json field must be an object');
        }
      }
      // No wrapper; treat the object itself as canonical
      return Map<String, dynamic>.from(decoded as Map);
    }
    throw const FormatException('Expected a JSON object');
  }

  Map<String, dynamic> _parseAssetToMap(String body) {
    final dynamic decoded = json.decode(body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    throw const FormatException('Asset canonical_contract.json must be a JSON object');
  }

  void _log(String message) {
    if (kDebugMode) {
      // Use debugPrint to avoid log truncation on long messages
      debugPrint('[ContractService] $message');
    }
  }
}