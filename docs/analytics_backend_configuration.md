# Analytics Backend URL Configuration

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
- For local builds, `assets/contracts/canonical.json` may define placeholders, e.g.:
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

## Testing and Docs
- Run tests: `flutter test`.
- Test logs are recorded in `docs/flutter-test-results.md` (see Run 4 for analytics-related outputs).

## Troubleshooting
- 401 Unauthorized: Configure your backend to accept unauthenticated analytics or attach required auth headers.
- Empty URL after env resolution: Ensure `.env` defines `ANALYTICS_BACKEND_URL` with a full URL.
- No button visible: The test button only appears in debug builds (`kDebugMode`).