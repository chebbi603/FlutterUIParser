// ContractResult model and ContractSource enum
// Provides a typed wrapper around canonical/personalized contract payloads
// with convenient helpers and serialization for logging/analytics.

enum ContractSource {
  canonical,
  personalized;

  // Return lowercase identifier for analytics serialization
  @override
  String toString() => name;
}

class ContractResult {
  final Map<String, dynamic> contract;
  final ContractSource source;
  final String version;
  final String? userId;

  const ContractResult({
    required this.contract,
    required this.source,
    required this.version,
    this.userId,
  });

  bool get isPersonalized => source == ContractSource.personalized;
  bool get isCanonical => source == ContractSource.canonical;

  /// Factory that accepts a backend response and extracts contract payload
  /// and metadata. It supports both raw canonical maps and wrapper objects
  /// that include a `json` field and optional metadata fields.
  factory ContractResult.fromBackendResponse(Map<String, dynamic> response) {
    // Extract contract payload: prefer wrapper `json` object if present
    final Map<String, dynamic> payload = response['json'] is Map
        ? Map<String, dynamic>.from(response['json'] as Map)
        : Map<String, dynamic>.from(response);

    // Resolve source from response or metadata (default to canonical)
    final String? sourceStr = _firstNonEmptyString([
      response['source'],
      (response['meta'] is Map) ? (response['meta'] as Map)['source'] as String? : null,
      (response['metadata'] is Map) ? (response['metadata'] as Map)['source'] as String? : null,
      payload['source'] as String?,
    ])?.toLowerCase();
    final ContractSource resolvedSource =
        sourceStr == 'personalized' ? ContractSource.personalized : ContractSource.canonical;

    // Resolve version from common locations
    final String? resolvedVersion = _firstNonEmptyString([
      response['version'],
      (response['meta'] is Map) ? (response['meta'] as Map)['version'] as String? : null,
      (response['metadata'] is Map) ? (response['metadata'] as Map)['version'] as String? : null,
      payload['version'] as String?,
      (payload['metadata'] is Map) ? (payload['metadata'] as Map)['version'] as String? : null,
    ]);

    // Resolve userId when present (personalized payloads)
    final String? resolvedUserId = _firstNonEmptyString([
      response['userId'],
      response['user_id'],
      (response['meta'] is Map) ? (response['meta'] as Map)['userId'] as String? : null,
      (response['metadata'] is Map) ? (response['metadata'] as Map)['userId'] as String? : null,
      payload['userId'] as String?,
      payload['user_id'] as String?,
    ]);

    return ContractResult(
      contract: payload,
      source: resolvedSource,
      version: resolvedVersion ?? '0.0.0',
      userId: resolvedUserId,
    );
  }

  ContractResult copyWith({
    Map<String, dynamic>? contract,
    ContractSource? source,
    String? version,
    String? userId,
  }) {
    return ContractResult(
      contract: contract ?? this.contract,
      source: source ?? this.source,
      version: version ?? this.version,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source.toString(),
      'version': version,
      'userId': userId,
      'contract': contract,
    };
  }

  @override
  String toString() => 'ContractResult(source: ${source.toString()}, version: $version, userId: ${userId ?? 'null'})';

  static String? _firstNonEmptyString(List<dynamic> candidates) {
    for (final dynamic c in candidates) {
      if (c is String) {
        final trimmed = c.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return null;
  }
}