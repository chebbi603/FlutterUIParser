# Analytics Backend URL Configuration

Project: `demo_json_parser` (Flutter)

This document defines how the app discovers and uses the Analytics backend URL and clarifies that the application now operates without any local contract asset fallback. All contract and analytics data must come from the backend.

## Summary of Architectural Change
- Local contract asset fallback removed: `assets/canonical_contract.json` has been deleted and is no longer bundled.
- The package manifest (`pubspec.yaml`) no longer references the removed asset; only `.env` and other necessary assets remain.
- Builds and analysis verified successfully after removal.

## Backend URL Resolution
- Primary source: `.env` file loaded by `flutter_dotenv`.
- Key: `API_BASE_URL` (already used across the app’s services).
- If `.env` is missing or not initialized, the app defaults to `http://localhost:8081` for developer environments.

Example `.env`:

```
API_BASE_URL=https://api.your-backend.example
ANALYTICS_BASE_URL=https://analytics.your-backend.example
```

## Service Integration Points
- Contract fetcher: `lib/services/contract_service.dart`
  - Fetches the canonical contract only from the backend.
  - Asset fallback has been removed at the project level; ensure backend availability.
- Analytics client: `lib/analytics/` modules read `ANALYTICS_BASE_URL` if defined; otherwise they derive from `API_BASE_URL`.

## Operational Guidance
- Ensure backend endpoints are reachable before launching the app.
- For local development, start the backend at `http://localhost:8081` or update `.env` accordingly.
- When running `flutter run`, verify logs for successful contract and analytics initialization.

## Verification Checklist
- No `assets/canonical_contract.json` file in the repository.
- `pubspec.yaml` contains no reference to `assets/canonical_contract.json`.
- `AssetManifest.json` in build artifacts does not list `assets/canonical_contract.json`.

## Impact on Documentation and Tests
- All docs referencing local contract fallback must be considered legacy; this document supersedes those mentions.
- Tests should assume backend‑only contract loading; widget and integration tests should mock HTTP responses rather than assets.

This document describes how the analytics backend URL is configured from the canonical contract and how to verify event flushes during development.

## Contract JSON Structure
- Root-level key: `analytics`
- Required property for backend: `backendUrl`
- Example:
```
{
  "analytics": {
    "backendUrl": "http://localhost:8081/events",
    "trackedComponents": ["email", "loginEmail", "loginPassword"],
    "wsUrl": "http://localhost:8081/ws"
  }
}
```

### Environment Variable Placeholders
- The canonical contract delivered by the backend may define placeholders, e.g.:
```
"backendUrl": "${ANALYTICS_BACKEND_URL}",
"wsUrl": "${WS_URL}"
```
- Placeholders are resolved from `.env` at startup. Ensure `.env` sets `ANALYTICS_BACKEND_URL` to a full URL, including protocol, host, port, and path:
```
ANALYTICS_BACKEND_URL=http://localhost:8081/events
```

## App Startup Integration
- On boot, `lib/main.dart` extracts the analytics configuration from the loaded contract map and configures the `AnalyticsService` singleton.
- Helper functions:
  - `_extractAnalyticsBackendUrl(Map<String, dynamic>)` — reads `contract['analytics']['backendUrl']`.
  - `_resolveEnvVarsInUrl(String?)` — replaces `${VAR}` with values from `.env` and logs a warning if the URL is not absolute.
- Logs:
  - Success: `Analytics configured: http://localhost:8081/events`
  - Disabled: `Analytics disabled: no backendUrl in contract`

## Debug-Only Test Event Flush
- A development-only button labeled `Send Test Analytics` appears under the refresh banner on all pages.
- When pressed (debug builds only):
  - Tracks a `custom` event with `componentId = "test-button"` and `data.tag = "test"`.
  - Immediately calls `AnalyticsService.flush()`.
  - Console prints tracked event and flush result, e.g.:
```
📊 Tracked: custom (component=test-button, page=null, tag=test)
🚀 Flushed 1/1 events to backend
```
- If the backend requires authentication or the URL is not configured, you may see:
```
⚠️ No backendUrl configured; keeping N events in memory
❌ Flush failed: 401 { ... }
```

## Backend Verification
- Confirm that your canonical contract served by the backend contains:
```
"analytics": { "backendUrl": "http://localhost:8081/events" }
```
- Ensure the URL is complete (protocol, host, port, path) — e.g. `http://localhost:8081/events`.
- Check backend logs or database to verify a POST batch is received when flush runs.
- The service sends an array of simplified events with `timestamp`, `componentId`, and `eventType` keys.

### Contract Attribution Fields (added)
- Client includes the following on each event when `AnalyticsService` is properly wired:
  - `contractType` (`canonical` | `personalized` | `unknown`)
  - `contractVersion` (string)
  - `isPersonalized` (boolean)
  - `userId` (string or null)
- Ensure your ingestion pipeline tolerates missing values and uses these fields for segmentation.

## Testing and Docs
- Run tests: `flutter test`.
- Test logs are recorded in `docs/flutter-test-results.md` (see Run 4 for analytics-related outputs).

## Troubleshooting
- 401 Unauthorized: Configure your backend to accept unauthenticated analytics or attach required auth headers.
- 401 behavior: client halts flush and clears events that contain `userId`, preventing retry loops.
- Empty URL after env resolution: Ensure `.env` defines `ANALYTICS_BACKEND_URL` with a full URL.
- No button visible: The test button only appears in debug builds (`kDebugMode`).
### Page Scope Field (new)
- Client enriches events with `pageScope`:
  - Values: `public` | `authenticated`
  - Computed from contract routes (`auth`) or bottom navigation `authRequired`; defaults to `authenticated` when unknown.
- Ingestion guidance:
  - Segment KPIs and funnels by `pageScope` to separate pre‑auth vs post‑auth behavior.
  - Treat `login`, `signup`, and password flows as `public` journeys; verify your contract routes reflect this via `auth` flags.

Example (server‑received event):
```json
{
  "timestamp": 1681836102000,
  "componentId": "login_button",
  "eventType": "tap",
  "pageId": "login",
  "pageScope": "public",
  "contractType": "canonical",
  "contractVersion": "1.0.0",
  "isPersonalized": false,
  "userId": null
}
```