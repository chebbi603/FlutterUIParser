import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import '../models/config_models.dart';

/// Enhanced API service with caching, retry policies, and contract validation
class EnhancedApiService {
  static final EnhancedApiService _instance = EnhancedApiService._internal();
  factory EnhancedApiService() => _instance;
  EnhancedApiService._internal();

  final Map<String, ServiceConfig> _services = {};
  final Map<String, CachedResponse> _cache = {};
  final Map<String, String> _authTokens = {};
  String? _baseApiUrl;
  CanonicalContract? _contract;

  /// Pending request deduplication: key -> in-flight future
  final Map<String, Future<ApiResponse<dynamic>>> _pending = {};

  /// Initialize the service with canonical contract
  void initialize(CanonicalContract contract) {
    _services.clear();
    _services.addAll(contract.services);
    _baseApiUrl = _extractBaseUrl();
    _contract = contract;
  }

  String? _extractBaseUrl() {
    // Extract base URL from environment or first service
    String? envBase;
    try {
      if (dotenv.isInitialized) {
        envBase = dotenv.env['API_BASE_URL'];
      }
    } catch (_) {
      // DotEnv not initialized or unavailable; fall back below
      envBase = null;
    }
    if (envBase != null && envBase.isNotEmpty) {
      return envBase;
    }
    if (_services.isNotEmpty) {
      final firstService = _services.values.first;
      final baseUrl = firstService.baseUrl;
      return baseUrl.replaceAll(
        RegExp(r'\$\{[^}]+\}'),
        'https://api.example.com',
      );
    }
    return null;
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authTokens['bearer'] = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authTokens.clear();
  }

  /// Make API call based on service and endpoint configuration
  Future<ApiResponse<T>> call<T>({
    required String service,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final serviceConfig = _services[service];
    if (serviceConfig == null) {
      throw ApiException('Service "$service" not found');
    }

    final endpointConfig = serviceConfig.endpoints[endpoint];
    if (endpointConfig == null) {
      throw ApiException(
        'Endpoint "$endpoint" not found in service "$service"',
      );
    }

    // Build URL
    final url = _buildUrl(
      serviceConfig.baseUrl,
      endpointConfig.path,
      queryParams,
      endpointConfig.queryParams,
    );

    // Build headers
    final requestHeaders = _buildHeaders(endpointConfig, headers);

    // Check cache
    final cached =
        endpointConfig.caching?.enabled == true ? _getFromCache(url) : null;
    if (cached != null) {
      return ApiResponse<T>(
        data: cached.data as T,
        statusCode: 200,
        headers: cached.headers,
        fromCache: true,
      );
    }

    // Compose deduplication key (method+url+body)
    final method = endpointConfig.method;
    final dedupKey = _dedupKey(method, url, data);

    // If a matching request is in-flight, await it and cast
    final existing = _pending[dedupKey];
    if (existing != null) {
      final shared = await existing;
      return ApiResponse<T>(
        data: shared.data as T,
        statusCode: shared.statusCode,
        headers: shared.headers,
        fromCache: shared.fromCache,
      );
    }

    // Start the request and store in pending
    final completer = _performRequest<T>(
      url: url,
      method: method,
      headers: requestHeaders,
      data: data,
      endpointConfig: endpointConfig,
    );
    _pending[dedupKey] = completer as Future<ApiResponse<dynamic>>;

    try {
      final result = await completer;
      return result;
    } finally {
      // Clean up pending regardless of success or failure
      _pending.remove(dedupKey);
    }
  }

  Future<ApiResponse<T>> _performRequest<T>({
    required String url,
    required String method,
    required Map<String, String> headers,
    Map<String, dynamic>? data,
    required EndpointConfig endpointConfig,
  }) async {
    final response = await _makeRequestWithRetry(
      url: url,
      method: method,
      headers: headers,
      body: data,
      retryPolicy: endpointConfig.retryPolicy,
    );

    // Validate response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseData = _parseResponse(response);

      // JSON Schema validation with $ref support
      if (endpointConfig.responseSchema != null) {
        _validateResponseSchema(responseData, endpointConfig.responseSchema!);
      }

      // Cache response if enabled
      if (endpointConfig.caching?.enabled == true) {
        _cacheResponse(
          url,
          responseData,
          response.headers,
          endpointConfig.caching!,
        );
      }

      return ApiResponse<T>(
        data: responseData as T,
        statusCode: response.statusCode,
        headers: response.headers,
        fromCache: false,
      );
    } else {
      final message = _getErrorMessage(
        response.statusCode,
        endpointConfig.errorCodes,
      );
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  String _buildUrl(
    String baseUrl,
    String path,
    Map<String, dynamic>? queryParams,
    Map<String, QueryParamConfig>? paramConfigs,
  ) {
    // Replace environment variables
    final resolvedBaseUrl = baseUrl.replaceAll(
      RegExp(r'\$\{[^}]+\}'),
      _baseApiUrl ?? 'https://api.example.com',
    );

    // Build query parameters with validation
    final Map<String, String> finalParams = {};

    // Add configured default parameters
    if (paramConfigs != null) {
      for (final entry in paramConfigs.entries) {
        final name = entry.key;
        final cfg = entry.value;
        final defaultValue = cfg.defaultValue;
        if (defaultValue != null) {
          finalParams[name] = defaultValue.toString();
        }
      }
    }

    // Add provided parameters and validate
    if (queryParams != null) {
      for (final entry in queryParams.entries) {
        final name = entry.key;
        final value = entry.value;
        final cfg = paramConfigs?[name];
        if (cfg != null) {
          _validateQueryParam(name, value, cfg);
        }
        finalParams[name] = value.toString();
      }
    }

    final query =
        finalParams.isEmpty
            ? ''
            : '?${finalParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    return '$resolvedBaseUrl$path$query';
  }

  String _dedupKey(String method, String url, Map<String, dynamic>? body) {
    final bodyJson = body == null ? '' : json.encode(body);
    return '$method::$url::$bodyJson';
  }

  Future<http.Response> _makeRequestWithRetry({
    required String url,
    required String method,
    required Map<String, String> headers,
    dynamic body,
    RetryPolicyConfig? retryPolicy,
  }) async {
    int attempts = 0;
    final maxAttempts = retryPolicy?.maxAttempts ?? 1;
    final backoffMs = retryPolicy?.backoffMs ?? 1000;

    while (attempts < maxAttempts) {
      try {
        attempts++;

        final uri = Uri.parse(url);
        // Debug: print outgoing request
        try {
          final safeHeaders = Map<String, String>.from(headers);
          if (safeHeaders.containsKey('Authorization')) {
            safeHeaders['Authorization'] = '[REDACTED Bearer]';
          }
          debugPrint('[HTTP Request] ${method.toUpperCase()} ${uri.toString()}');
          debugPrint('[HTTP Headers] ${json.encode(safeHeaders)}');
          if (body != null) {
            final bodyStr = body is String ? body : json.encode(body);
            // Truncate very long bodies for readability
            final truncated = bodyStr.length > 200
                ? bodyStr.substring(0, 200) + '…(truncated)'
                : bodyStr;
            debugPrint('[HTTP Body] $truncated');
          }
        } catch (e) {
          debugPrint('[HTTP Debug] Failed to log request: $e');
        }
        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: headers);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            );
            break;
          case 'PATCH':
            response = await http.patch(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            );
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: headers);
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
        }

        // Debug: print response summary
        try {
          final bodyStr = response.body;
          final truncated = bodyStr.length > 500
              ? bodyStr.substring(0, 500) + '…(truncated)'
              : bodyStr;
          debugPrint('[HTTP Response] ${response.statusCode} ${method.toUpperCase()} ${uri.toString()}');
          debugPrint('[Response Body] $truncated');
        } catch (e) {
          debugPrint('[HTTP Debug] Failed to log response: $e');
        }

        // Return successful response or non-retryable error
        if (response.statusCode < 500 || attempts >= maxAttempts) {
          return response;
        }

        // Wait before retry for server errors
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: backoffMs * attempts));
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          throw ApiException('Request failed after $maxAttempts attempts: $e');
        }

        // Wait before retry
        await Future.delayed(Duration(milliseconds: backoffMs * attempts));
      }
    }

    throw ApiException('Request failed after $maxAttempts attempts');
  }

  dynamic _parseResponse(http.Response response) {
    try {
      // Debug: log before parsing
      debugPrint('[HTTP Parse] status=${response.statusCode}, length=${response.body.length}');
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } catch (e) {
      throw ApiException('Failed to parse response: $e');
    }
  }

  void _validateQueryParam(
    String name,
    dynamic value,
    QueryParamConfig config,
  ) {
    // Type validation
    switch (config.type) {
      case 'integer':
        if (value is! int && int.tryParse(value.toString()) == null) {
          throw ApiException('Parameter "$name" must be an integer');
        }
        final intValue = value is int ? value : int.parse(value.toString());
        if (config.min != null && intValue < config.min!) {
          throw ApiException('Parameter "$name" must be >= ${config.min}');
        }
        if (config.max != null && intValue > config.max!) {
          throw ApiException('Parameter "$name" must be <= ${config.max}');
        }
        break;
      default:
        if (config.minLength != null &&
            value.toString().length < config.minLength!) {
          throw ApiException(
            'Parameter "$name" must be at least ${config.minLength} characters',
          );
        }
        if (config.enumValues != null &&
            !config.enumValues!.contains(value.toString())) {
          throw ApiException(
            'Parameter "$name" must be one of ${config.enumValues}',
          );
        }
        break;
    }
  }

  void _validateResponseSchema(dynamic data, Map<String, dynamic> schema) {
    // Supports: type, properties, required, items, $ref to dataModels
    if (schema['type'] == 'object') {
      if (data is! Map<String, dynamic>) {
        throw ApiException('Response must be an object');
      }
      // Required fields
      if (schema['required'] is List) {
        final required = List<String>.from(schema['required']);
        for (final field in required) {
          if (!data.containsKey(field)) {
            throw ApiException('Response missing required field "$field"');
          }
        }
      }
      // Properties validation
      if (schema['properties'] is Map<String, dynamic>) {
        final Map<String, dynamic> props =
            schema['properties'] as Map<String, dynamic>;
        for (final entry in props.entries) {
          final key = entry.key;
          final Map<String, dynamic> propSchema =
              (entry.value is Map<String, dynamic>)
                  ? Map<String, dynamic>.from(entry.value as Map)
                  : <String, dynamic>{};
          // Only validate properties that are present. Optional fields are allowed to be absent.
          if (!data.containsKey(key)) {
            continue;
          }
          final value = data[key];
          _validateValueAgainstSchema(key, value, propSchema);
        }
      }
    }
  }

  void _validateValueAgainstSchema(
    String key,
    dynamic value,
    Map<String, dynamic> schema,
  ) {
    // Optional fields: if value is null or not present, skip unless object-level 'required' enforces presence.
    if (value == null) {
      return;
    }
    final type = schema['type'];
    if (type == 'array') {
      if (value is! List) {
        throw ApiException('Field "$key" must be an array');
      }
      final items = schema['items'];
      if (items is Map<String, dynamic>) {
        final refPath = items[r'$ref'];
        if (refPath is String && refPath.startsWith('#/dataModels/')) {
          final modelName = refPath.substring('#/dataModels/'.length);
          _validateArrayItemsAgainstModel(key, value, modelName);
        } else if (items['type'] is String) {
          for (final v in value) {
            _validatePrimitiveType('$key[]', v, items['type']);
          }
        }
      }
    } else if (type is String) {
      _validatePrimitiveType(key, value, type);
    } else if (schema[r'$ref'] is String) {
      final refPath = schema[r'$ref'] as String;
      if (refPath.startsWith('#/dataModels/')) {
        final modelName = refPath.substring('#/dataModels/'.length);
        _validateObjectAgainstModel(key, value, modelName);
      }
    }
  }

  void _validatePrimitiveType(String key, dynamic value, String type) {
    switch (type) {
      case 'string':
        if (value is! String) {
          // Accept common ObjectId-like map shapes by coercing to string
          final coerced = _coerceStringLike(value);
          if (coerced == null) {
            throw ApiException('Field "$key" must be string');
          }
        }
        break;
      case 'number':
        if (value is! num) {
          throw ApiException('Field "$key" must be number');
        }
        break;
      case 'boolean':
        if (value is! bool) {
          throw ApiException('Field "$key" must be boolean');
        }
        break;
      case 'object':
        if (value is! Map) throw ApiException('Field "$key" must be object');
        break;
      case 'array':
        if (value is! List) throw ApiException('Field "$key" must be array');
        break;
      default:
        break;
    }
  }

  /// Coerce common ID map shapes (e.g., Mongo ObjectId) into string values.
  /// Returns the extracted string when possible, otherwise null.
  String? _coerceStringLike(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      // Typical keys carrying string identifiers
      final keys = [r'$oid', 'oid', 'id', 'value', 'string', 'hex', 'hexString'];
      for (final k in keys) {
        final v = value[k];
        if (v is String) return v;
      }
    }
    return null;
  }

  void _validateArrayItemsAgainstModel(
    String key,
    List<dynamic> array,
    String modelName,
  ) {
    final model = _contract?.dataModels[modelName];
    if (model == null) return;
    for (final item in array) {
      _validateAgainstDataModel('$key[]', item, model);
    }
  }

  void _validateObjectAgainstModel(String key, dynamic obj, String modelName) {
    final model = _contract?.dataModels[modelName];
    if (model == null) return;
    _validateAgainstDataModel(key, obj, model);
  }

  void _validateAgainstDataModel(String key, dynamic obj, DataModel model) {
    if (obj is! Map<String, dynamic>) {
      throw ApiException('Field "$key" must be object matching model');
    }
    for (final entry in model.fields.entries) {
      final fieldName = entry.key;
      final cfg = entry.value;
      if (cfg.required && !obj.containsKey(fieldName)) {
        throw ApiException('Field "$key.$fieldName" is required');
      }
      final v = obj[fieldName];
      if (v == null) continue;
      switch (cfg.type) {
        case 'string':
          if (v is! String) {
            // Accept common ObjectId-like map shapes by coercing to string
            final coerced = _coerceStringLike(v);
            if (coerced == null) {
              throw ApiException('Field "$key.$fieldName" must be string');
            }
          }
          if (cfg.minLength != null && v.length < cfg.minLength!) {
            throw ApiException(
              'Field "$key.$fieldName" minLength ${cfg.minLength}',
            );
          }
          if (cfg.maxLength != null && v.length > cfg.maxLength!) {
            throw ApiException(
              'Field "$key.$fieldName" maxLength ${cfg.maxLength}',
            );
          }
          break;
        case 'number':
        case 'int':
        case 'double':
          if (v is! num) {
            throw ApiException('Field "$key.$fieldName" must be number');
          }
          break;
        case 'boolean':
          if (v is! bool) {
            throw ApiException('Field "$key.$fieldName" must be boolean');
          }
          break;
        default:
          break;
      }
    }
  }

  String _getErrorMessage(int statusCode, Map<String, String>? errorCodes) {
    if (errorCodes != null && errorCodes.containsKey(statusCode.toString())) {
      return errorCodes[statusCode.toString()]!;
    }

    switch (statusCode) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 429:
        return 'Too Many Requests';
      case 500:
        return 'Internal Server Error';
      default:
        return 'Unexpected error ($statusCode)';
    }
  }

  Map<String, String> _buildHeaders(
    EndpointConfig config,
    Map<String, String>? additionalHeaders,
  ) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authentication if required
    if (config.auth != null) {
      if (config.auth == true || config.auth == 'bearer') {
        final token = _authTokens['bearer'];
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        } else if (config.auth == true) {
          throw ApiException('Authentication required but no token provided');
        }
      }
    }

    // Add additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  CachedResponse? _getFromCache(String url) {
    final cached = _cache[url];
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    if (cached != null && cached.isExpired) {
      _cache.remove(url);
    }
    return null;
  }

  void _cacheResponse(
    String url,
    dynamic data,
    Map<String, String> headers,
    CachingConfig config,
  ) {
    final ttl = config.ttlSeconds ?? 300; // Default 5 minutes
    final expiresAt = DateTime.now().add(Duration(seconds: ttl));

    _cache[url] = CachedResponse(
      data: data,
      headers: headers,
      expiresAt: expiresAt,
    );
  }

  /// Clear all cached responses
  void clearCache() {
    _cache.clear();
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => value.expiresAt.isBefore(now));
  }
}

/// API response wrapper
class ApiResponse<T> {
  final T data;
  final int statusCode;
  final Map<String, String> headers;
  final bool fromCache;

  ApiResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.fromCache,
  });
}

/// Cached response model
class CachedResponse {
  final dynamic data;
  final Map<String, String> headers;
  final DateTime expiresAt;

  CachedResponse({
    required this.data,
    required this.headers,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// API exception for error handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Service for managing API calls based on canonical contract
class ContractApiService {
  final EnhancedApiService _apiService = EnhancedApiService();
  CanonicalContract? _contract;
  AuthService? _authService;

  /// Initialize with canonical contract
  void initialize(CanonicalContract contract) {
    _contract = contract;
    _apiService.initialize(contract);
  }

  void attachAuthService(AuthService authService) {
    _authService = authService;
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  /// Clear authentication token
  void clearAuthToken() {
    _apiService.clearAuthToken();
  }

  /// Clear cache
  void clearCache() {
    _apiService.clearCache();
  }

  /// Make API call using service and endpoint names from contract
  Future<Map<String, dynamic>> call({
    required String service,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _apiService.call<Map<String, dynamic>>(
        service: service,
        endpoint: endpoint,
        data: data,
        queryParams: params,
      );
      return response.data;
    } on ApiException catch (e) {
      if (e.statusCode == 401 && _authService != null) {
        final refreshed = await _authService!.tryRefresh();
        if (refreshed) {
          final retry = await _apiService.call<Map<String, dynamic>>(
            service: service,
            endpoint: endpoint,
            data: data,
            queryParams: params,
          );
          return retry.data;
        }
      }
      rethrow;
    }
  }

  /// Fetch paginated list data
  Future<PaginatedResponse> fetchList({
    required String service,
    required String endpoint,
    Map<String, dynamic>? params,
    String listPath = 'data',
    String? totalPath,
    String? pagePath,
  }) async {
    final response = await _apiService.call<Map<String, dynamic>>(
      service: service,
      endpoint: endpoint,
      queryParams: params,
    );

    // Extract list data using path
    final listData = _extractByPath(response.data, listPath) as List? ?? [];

    // Extract pagination info
    int? total;
    int? currentPage;

    if (totalPath != null) {
      total = _extractByPath(response.data, totalPath) as int?;
    }

    if (pagePath != null) {
      currentPage = _extractByPath(response.data, pagePath) as int?;
    }

    return PaginatedResponse(
      data: List<dynamic>.from(listData),
      total: total,
      currentPage: currentPage,
      rawResponse: response.data,
    );
  }

  dynamic _extractByPath(Map<String, dynamic> data, String path) {
    dynamic current = data;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic>) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}

/// Paginated response model
class PaginatedResponse {
  final List<dynamic> data;
  final int? total;
  final int? currentPage;
  final Map<String, dynamic> rawResponse;

  PaginatedResponse({
    required this.data,
    this.total,
    this.currentPage,
    required this.rawResponse,
  });

  bool get hasMore {
    if (total == null || currentPage == null) return data.isNotEmpty;
    final pageSize = data.length;
    if (pageSize == 0) return false;
    final totalPages = (total! / pageSize).ceil();
    return currentPage! < totalPages;
  }
}
