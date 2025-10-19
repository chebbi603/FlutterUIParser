import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
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

  /// Initialize the service with canonical contract
  void initialize(CanonicalContract contract) {
    _services.clear();
    _services.addAll(contract.services);
    _baseApiUrl = _extractBaseUrl();
  }

  String? _extractBaseUrl() {
    // Extract base URL from environment or first service
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

    // Check cache first
    if (endpointConfig.method.toUpperCase() == 'GET' &&
        endpointConfig.caching?.enabled == true) {
      final cached = _getFromCache(url);
      if (cached != null) {
        return ApiResponse<T>(
          data: cached.data as T,
          statusCode: 200,
          headers: cached.headers,
          fromCache: true,
        );
      }
    }

    // Prepare headers
    final requestHeaders = _buildHeaders(endpointConfig, headers);

    // Validate request data
    if (endpointConfig.requestSchema != null && data != null) {
      _validateRequestData(data, endpointConfig.requestSchema!);
    }

    // Make request with retry policy
    final response = await _makeRequestWithRetry(
      url: url,
      method: endpointConfig.method,
      headers: requestHeaders,
      body: data,
      retryPolicy: endpointConfig.retryPolicy,
    );

    // Validate response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseData = _parseResponse(response);

      // Validate response schema
      if (endpointConfig.responseSchema != null) {
        _validateResponseData(responseData, endpointConfig.responseSchema!);
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
      final errorMessage = _getErrorMessage(
        response.statusCode,
        endpointConfig.errorCodes,
      );
      throw ApiException(errorMessage, statusCode: response.statusCode);
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

    final uri = Uri.parse('$resolvedBaseUrl$path');

    // Build query parameters with validation
    final Map<String, String> finalParams = {};

    // Add configured default parameters
    if (paramConfigs != null) {
      for (final entry in paramConfigs.entries) {
        final config = entry.value;
        if (config.defaultValue != null) {
          finalParams[entry.key] = config.defaultValue.toString();
        }
      }
    }

    // Add provided parameters with validation
    if (queryParams != null) {
      for (final entry in queryParams.entries) {
        if (entry.value != null) {
          final paramConfig = paramConfigs?[entry.key];
          if (paramConfig != null) {
            _validateQueryParam(entry.key, entry.value, paramConfig);
          }
          finalParams[entry.key] = entry.value.toString();
        }
      }
    }

    return uri
        .replace(queryParameters: finalParams.isNotEmpty ? finalParams : null)
        .toString();
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
          case 'DELETE':
            response = await http.delete(uri, headers: headers);
            break;
          case 'PATCH':
            response = await http.patch(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            );
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
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
      case 'string':
        final stringValue = value.toString();
        if (config.minLength != null &&
            stringValue.length < config.minLength!) {
          throw ApiException(
            'Parameter "$name" must be at least ${config.minLength} characters',
          );
        }
        if (config.enumValues != null &&
            !config.enumValues!.contains(stringValue)) {
          throw ApiException(
            'Parameter "$name" must be one of: ${config.enumValues!.join(', ')}',
          );
        }
        break;
    }
  }

  void _validateRequestData(
    Map<String, dynamic> data,
    Map<String, dynamic> schema,
  ) {
    // Basic JSON schema validation
    if (schema['required'] is List) {
      final required = List<String>.from(schema['required']);
      for (final field in required) {
        if (!data.containsKey(field) || data[field] == null) {
          throw ApiException('Required field "$field" is missing');
        }
      }
    }

    if (schema['properties'] is Map) {
      final properties = schema['properties'] as Map<String, dynamic>;
      for (final entry in data.entries) {
        final fieldSchema = properties[entry.key];
        if (fieldSchema != null) {
          _validateField(entry.key, entry.value, fieldSchema);
        }
      }
    }
  }

  void _validateResponseData(dynamic data, Map<String, dynamic> schema) {
    // Basic response validation
    if (data is Map<String, dynamic>) {
      _validateRequestData(data, schema);
    }
  }

  void _validateField(
    String fieldName,
    dynamic value,
    Map<String, dynamic> fieldSchema,
  ) {
    final type = fieldSchema['type'];

    switch (type) {
      case 'string':
        if (value is! String) {
          throw ApiException('Field "$fieldName" must be a string');
        }
        if (fieldSchema['minLength'] != null &&
            value.length < fieldSchema['minLength']) {
          throw ApiException(
            'Field "$fieldName" must be at least ${fieldSchema['minLength']} characters',
          );
        }
        if (fieldSchema['maxLength'] != null &&
            value.length > fieldSchema['maxLength']) {
          throw ApiException(
            'Field "$fieldName" must be at most ${fieldSchema['maxLength']} characters',
          );
        }
        if (fieldSchema['format'] == 'email' && !_isValidEmail(value)) {
          throw ApiException('Field "$fieldName" must be a valid email');
        }
        break;
      case 'integer':
        if (value is! int) {
          throw ApiException('Field "$fieldName" must be an integer');
        }
        break;
      case 'array':
        if (value is! List) {
          throw ApiException('Field "$fieldName" must be an array');
        }
        break;
      case 'object':
        if (value is! Map) {
          throw ApiException('Field "$fieldName" must be an object');
        }
        break;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
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
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return 'Request failed with status $statusCode';
    }
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

  /// Initialize with canonical contract
  void initialize(CanonicalContract contract) {
    _contract = contract;
    _apiService.initialize(contract);
  }

  /// Make API call using service and endpoint names from contract
  Future<Map<String, dynamic>> call({
    required String service,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) async {
    if (_contract == null) {
      throw ApiException('Contract not initialized');
    }

    final response = await _apiService.call<Map<String, dynamic>>(
      service: service,
      endpoint: endpoint,
      data: data,
      queryParams: params,
    );

    return response.data;
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
    final response = await call(
      service: service,
      endpoint: endpoint,
      params: params,
    );

    // Extract list data using path
    final listData = _extractByPath(response, listPath) as List? ?? [];

    // Extract pagination info
    int? total;
    int? currentPage;

    if (totalPath != null) {
      total = _extractByPath(response, totalPath) as int?;
    }

    if (pagePath != null) {
      currentPage = _extractByPath(response, pagePath) as int?;
    }

    return PaginatedResponse(
      data: listData,
      total: total,
      currentPage: currentPage,
      rawResponse: response,
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
    final totalPages = (total! / pageSize).ceil();
    return currentPage! < totalPages;
  }
}
