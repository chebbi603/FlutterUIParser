import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:demo_json_parser/models/contract_result.dart';

/// ContractService handles fetching the canonical contract JSON from the backend
/// with a robust fallback strategy and clear error logging.
///
/// - Primary endpoint: `GET {baseUrl}/contracts/canonical`
/// - Fallback endpoint: `GET {baseUrl}/contracts/public/canonical`
/// - No local asset fallback: backend must be available
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

  /// Fetch canonical contract and return as a ContractResult.
  ///
  /// Primary endpoint: `/contracts/canonical`
  /// Fallback endpoint: `/contracts/public/canonical`
  /// No local asset fallback. Throws on failure.
  Future<ContractResult> fetchCanonicalContract() async {
    // 1) Try primary backend endpoint
    try {
      final primaryUrl = _buildUrl('/contracts/canonical');
      _log('Attempting primary endpoint: GET $primaryUrl');
      final response = await _client
          .get(primaryUrl, headers: _jsonHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _log('Primary endpoint succeeded (200)');
        final map = _parseJsonToMap(response.body, source: 'primary response');
        _validateContractStructure(map);
        final version = _extractVersion(map);
        return ContractResult(
          contract: map,
          source: ContractSource.canonical,
          version: version,
        );
      } else {
        _logHttpFailure('fetchCanonicalContract', primaryUrl, response);
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
        final map = _parseJsonToMap(response.body, source: 'fallback response');
        _validateContractStructure(map);
        final version = _extractVersion(map);
        return ContractResult(
          contract: map,
          source: ContractSource.canonical,
          version: version,
        );
      } else {
        _logHttpFailure('fetchCanonicalContract', fallbackUrl, response);
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

    // 3) No local fallback: propagate failure
    _log('All backend endpoints failed; backend unavailable. Throwing error.');
    throw Exception('Backend unavailable: failed to fetch canonical contract');
  }

  Map<String, String> get _jsonHeaders => const {
        'Accept': 'application/json',
      };
  Map<String, String> _authHeaders(String jwtToken) => {
        ..._jsonHeaders,
        'Authorization': 'Bearer $jwtToken',
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
          return Map<String, dynamic>.from(inner);
        } else {
          throw const FormatException('Wrapper json field must be an object');
        }
      }
      // No wrapper; treat the object itself as canonical
      return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Expected a JSON object');
  }

  /// Validate that required root objects exist to prevent downstream UI errors.
  void _validateContractStructure(Map<String, dynamic> contract) {
    final hasMeta = contract['meta'] is Map;
    final hasPages = contract['pagesUI'] is Map;
    if (!hasMeta || !hasPages) {
      throw const FormatException('Contract validation failed: missing meta/pagesUI');
    }
  }

  /// Extract version from `meta.version`, defaulting to "unknown" if absent.
  String _extractVersion(Map<String, dynamic> contract) {
    try {
      final meta = contract['meta'] as Map<String, dynamic>?;
      final v = meta?['version'];
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return 'unknown';
  }

  /// Fetch a personalized user-specific contract using JWT authentication.
  ///
  /// Endpoint: `/users/{userId}/contract`
  /// - Adds `Authorization: Bearer <jwtToken>`
  /// - On 401: throws AuthenticationException
  /// - On 404: falls back to canonical contract
  Future<ContractResult> fetchUserContract({
    required String userId,
    required String jwtToken,
  }) async {
    final url = _buildUrl('/users/$userId/contract');
    _log('Attempting user contract: GET $url');
    try {
      final response = await _client
          .get(url, headers: _authHeaders(jwtToken))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _log('User contract succeeded (200)');
        final map = _parseJsonToMap(response.body, source: 'user response');
        _validateContractStructure(map);
        final version = _extractVersion(map);
        return ContractResult(
          contract: map,
          source: ContractSource.personalized,
          version: version,
          userId: userId,
        );
      }

      if (response.statusCode == 401) {
        _logHttpFailure('fetchUserContract', url, response);
        throw AuthenticationException('JWT invalid or expired');
      }
      if (response.statusCode == 404) {
        _log('[fetchUserContract] 404 Not Found → falling back to canonical');
        return await fetchCanonicalContract();
      }

      _logHttpFailure('fetchUserContract', url, response);
      throw Exception('User contract request failed: ${response.statusCode}');
    } on TimeoutException catch (e) {
      _log('User contract timed out: $e');
      rethrow;
    } on FormatException catch (e) {
      _log('User contract returned malformed JSON: $e');
      rethrow;
    } on http.ClientException catch (e) {
      _log('User contract client error: $e');
      rethrow;
    } catch (e) {
      _log('User contract error: $e');
      rethrow;
    }
  }

  // No asset parsing in backend-only mode.

  void _log(String message) {
    if (kDebugMode) {
      // Use debugPrint to avoid log truncation on long messages
      debugPrint('[ContractService] $message');
    }
  }

  void _logHttpFailure(String method, Uri url, http.Response response) {
    _log('[$method] HTTP ${response.statusCode} for $url → ${response.body.length} bytes');
  }
}

/// Semantic exception for authentication failures.
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  @override
  String toString() => 'AuthenticationException: $message';
}