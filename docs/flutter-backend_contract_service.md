Project: demo_json_parser (Flutter)
# Backend Contract Service

This document describes the `ContractService` responsible for fetching the canonical and user‑specific JSON contracts from the backend with robust fallbacks and clear diagnostics. The local asset fallback has been removed; the app now operates in backend‑only mode for contract loading.

## Overview
- Location: `lib/services/contract_service.dart`
- Purpose: Load contracts from the backend and return typed `ContractResult` objects that include the payload, source, version, and optional `userId`. Asset fallback has been removed.
- Constructor: `ContractService({ required String baseUrl, http.Client? client, Duration? timeout })`
- Methods:
  - `Future<ContractResult> fetchCanonicalContract()`
  - `Future<ContractResult> fetchUserContract({ required String userId, required String jwtToken })`

## HTTP Configuration
- Package: `http` (`pubspec.yaml` already contains `http: ^1.5.0`)
- Timeout: `10s` enforced per request using `.timeout(Duration(seconds: 10))`
- Headers: `Accept: application/json`
- URL join: Safe join of `baseUrl` with endpoint path (`/contracts/canonical`, `/contracts/public/canonical`, `/users/{userId}/contract`).

## Fallback Strategy
### Canonical
1. Primary: `GET {baseUrl}/contracts/canonical`
   - On `200`, parse and return JSON.
2. Fallback: `GET {baseUrl}/contracts/public/canonical`
   - Attempted when primary fails (non-200 or exception).
3. No local asset fallback: ensure backend availability or mock HTTP in tests.

### Personalized (User‑specific)
- Endpoint: `GET {baseUrl}/users/{userId}/contract`
- Headers: `Authorization: Bearer <jwtToken>` and `Accept: application/json`
- Timeout: `10s`
- On `200`: parse, validate shape, wrap as `ContractResult(source: personalized, userId)`
- On `401`: throw `AuthenticationException` (JWT invalid/expired)
- On `404`: fall back to `fetchCanonicalContract()` automatically

## Response Parsing
- Supports both raw object payloads and wrapper DTOs containing a `json` field:
  - Raw: `{ ...canonical contract... }`
  - Wrapper: `{ "json": { ...canonical contract... }, ... }`
- Returns `ContractResult` with `contract` map and `source` enum (`canonical` or `personalized`).
- Validates presence of required root objects: `meta` and `pagesUI`.
- Extracts version from `meta.version`, defaulting to `"unknown"` when missing.

## Error Handling & Logging
- Exceptions caught: `TimeoutException`, `FormatException`, `http.ClientException`, plus generic `Exception` for cross-platform network errors.
- Logs each step with context: primary attempt, fallback attempt, and all caught exceptions.

## Usage Example
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/contract_service.dart';

Future<void> loadContracts() async {
  final base = (dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null) ?? 'http://localhost:8081';
  final service = ContractService(baseUrl: base);

  // Canonical
  final canonical = await service.fetchCanonicalContract();

  // Personalized (requires auth)
  try {
    final personalized = await service.fetchUserContract(userId: '123', jwtToken: 'eyJhbGci...');
    // Use personalized.contract in UI
  } on AuthenticationException {
    // Prompt re-login or refresh token
  }
}
```

## Integration Tips
- For environment-based configuration, set `API_BASE_URL` in `.env` and load via `flutter_dotenv` (already integrated in `lib/main.dart`).
- When integrating with existing boot flow (`lib/app.dart`), the service can be used as a simpler fetcher; the current project also includes `ContractLoader` which handles caching, polling, and typed model mapping.

## Success Metrics
- Canonical and personalized contracts return `ContractResult` with correct `source` values.
- 404 on user contract triggers canonical fallback.
- 401 throws `AuthenticationException` for auth flows.
- Every network error path logs actionable context for debugging.