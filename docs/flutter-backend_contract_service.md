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
 - Base URL resolution order (frontend):
   1. `.env` keys `API_BASE_URL` or `API_URL`
   2. Compile-time defines `API_BASE_URL` or `API_URL`
   3. Default `http://localhost:8081`
   4. Android emulator: `localhost` remaps to `http://10.0.2.2:<port>`

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
- Trusts backend structure; no client-side schema validation. UI selects safe defaults when optional fields are absent.
- Extracts version from `meta.version`, defaulting to `"unknown"` when missing.

## Error Handling & Logging
- Exceptions caught: `TimeoutException`, `FormatException`, `http.ClientException`, plus generic `Exception` for cross-platform network errors.
- Logs each step with context: primary attempt, fallback attempt, and all caught exceptions.
 
## Backend-only Validation (updated)
- Client-side schema checks and `ContractValidator` have been removed.
- Validation is enforced on the backend (NestJS); the client renders defensively and surfaces errors via `ContractProvider.error`.
- Rationale: Avoid drift between client schemas and server contracts; simplify client and streamline iteration.

## Usage Example
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/contract_service.dart';

Future<void> loadContracts() async {
  final envBase = dotenv.isInitialized
      ? (dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'])
      : null;
  const defineBase = String.fromEnvironment('API_BASE_URL', defaultValue: '')
      .isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : const String.fromEnvironment('API_URL', defaultValue: '');
  final base = envBase ?? (defineBase.isNotEmpty ? defineBase : 'http://localhost:8081');
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
## Detailed Merge Logging (added)
- Summary logging:
  - On successful canonical fetch (primary and fallback) and personalized fetch, the service prints a concise summary:
    - `source` (`canonical`/`personalized`), `version`, counts of `pages` and `routes`, optional `userId`.
  - If merge hints exist (`mergeMetadata`, `isPartial`, `mergedPages`), it logs merge status and a best‑effort `mergedPagesCount`.
- Verbose mode:
  - `verboseMergeLogging` (default `kDebugMode`) prints the list of page IDs to aid diff/debug.
  - You can toggle at runtime: `service.verboseMergeLogging = true;`.
- Sample logs:
```
[fetchCanonicalContract:primary] source=canonical, version=1.2.3, pages=18, routes=9
[fetchCanonicalContract:primary] mergeMetadata: isPartial=false, mergedPagesCount=18
[fetchUserContract] source=personalized, version=1.2.3-p1, pages=20, routes=9, userId=123
[fetchUserContract] mergedPagesCount=2, isPartial=true
[fetchUserContract] page IDs: home, catalog, cart, checkout, profile, login, signup, forgotPassword, ...
```
- Rationale: These logs make it straightforward to confirm successful merges, diagnose unexpected missing pages, and validate route auth coverage.