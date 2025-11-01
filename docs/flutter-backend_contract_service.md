Project: demo_json_parser (Flutter)
# Backend Contract Service

This document describes the `ContractService` responsible for fetching the canonical JSON contract from the backend with robust fallbacks and clear diagnostics.

## Overview
- Location: `lib/services/contract_service.dart`
- Purpose: Load the canonical UI contract as `Map<String, dynamic>` from the backend. If the backend is unavailable or returns non-200, fall back to `assets/canonical_contract.json` to ensure the app boots reliably.
- Constructor: `ContractService({ required String baseUrl, http.Client? client, Duration? timeout })`
- Method: `Future<Map<String, dynamic>> fetchCanonicalContract()`

## HTTP Configuration
- Package: `http` (`pubspec.yaml` already contains `http: ^1.5.0`)
- Timeout: `10s` enforced per request using `.timeout(Duration(seconds: 10))`
- Headers: `Accept: application/json`
- URL join: Safe join of `baseUrl` with endpoint path (`/contracts/canonical`, `/contracts/public/canonical`).

## Fallback Strategy
1. Primary: `GET {baseUrl}/contracts/canonical`
   - On `200`, parse and return JSON.
2. Fallback: `GET {baseUrl}/contracts/public/canonical`
   - Attempted when primary fails (non-200 or exception).
3. Local asset: `assets/canonical_contract.json`
   - Loaded via `rootBundle.loadString` as the final fallback to prevent startup failure when the backend is unavailable.

## Response Parsing
- Supports both raw object payloads and wrapper DTOs containing a `json` field:
  - Raw: `{ ...canonical contract... }`
  - Wrapper: `{ "json": { ...canonical contract... }, ... }`
- Returns the canonical contract as `Map<String, dynamic>`.

## Error Handling & Logging
- Exceptions caught: `TimeoutException`, `FormatException`, `http.ClientException`, plus generic `Exception` for cross-platform network errors.
- Logs each step with context: primary attempt, fallback attempt, asset fallback, and all caught exceptions.
- Asset parsing enforces object type; malformed asset fails fast with clear error.

## Usage Example
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/contract_service.dart';

Future<Map<String, dynamic>> loadCanonical() async {
  final base = (dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null) ?? 'http://localhost:8081';
  final service = ContractService(baseUrl: base);
  return await service.fetchCanonicalContract();
}
```

## Integration Tips
- Ensure assets are declared in `pubspec.yaml`:
  - `assets:` → `- assets/canonical_contract.json`
- For environment-based configuration, set `API_BASE_URL` in `.env` and load via `flutter_dotenv` (already integrated in `lib/main.dart`).
- When integrating with existing boot flow (`lib/app.dart`), the service can be used as a simpler fetcher; the current project also includes `ContractLoader` which handles caching, polling, and typed model mapping.

## Success Metrics
- Backend available: Contract loads from primary/fallback in under ~3s.
- Backend unavailable: App starts using local asset with no user-visible errors.
- Every network error path logs actionable context for debugging.