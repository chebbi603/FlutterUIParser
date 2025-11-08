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

### Path Normalization (new)
- The client normalizes common misconfigurations to the canonical ingestion path `'/events'`.
- If the contract or env provides any of the below, it will be coerced to `http://<host>:<port>/events`:
  - `http://<host>:<port>/` (empty path)
  - `http://<host>:<port>/analytics`
  - `http://<host>:<port>/analytics/`
  - Any URL whose path ends with `/analytics/events`
- Rationale: some setups expose analytics under `/analytics/events`; this app expects `/events` as the root ingestion endpoint for consistency across environments.

### Contract-Level Normalization (new)
- In addition to URL normalization at startup, the contract parser enforces canonical endpoint paths for the `analytics` service.
- Behavior:
  - Service name aliases like `AnalyticsService` or `analytics` are supported and treated equivalently.
  - Any analytics endpoint with a legacy event path (`'/event'`, `'/events'`, or `'/analytics(/event|/events)'`) is coerced to `'/events'` during parsing.
  - Trailing `'/analytics'` on a service `baseUrl` is trimmed to avoid double paths.
- Example input contract snippet (legacy):
```json
{
  "services": {
    "AnalyticsService": {
      "baseUrl": "http://localhost:8081/analytics",
      "endpoints": {
        "trackEvent": { "method": "POST", "path": "/event" }
      }
    }
  }
}
```
- Result after parsing (effective configuration):
```json
{
  "services": {
    "analytics": {
      "baseUrl": "http://localhost:8081",
      "endpoints": {
        "trackEvent": { "method": "POST", "path": "/events" }
      }
    }
  }
}
```
- Impact:
  - Prevents requests like `POST /analytics/event` and ensures `POST /events` is used consistently.
  - Keeps older contracts functional without backend changes.

### Action Routing (trackEvent)
- To ensure consistent ingestion and visibility in MongoDB, contract actions that call the analytics service `trackEvent` endpoint are routed through `AnalyticsService` batching.
- Behavior:
  - When an action specifies `service: 'analytics'` (or `AnalyticsService`) and `endpoint: 'trackEvent'`, the dispatcher converts the provided payload (e.g., `{ event, feature, action }`) into a structured `TrackingEvent` via `AnalyticsService.trackComponentInteraction(...)`.
  - The client immediately calls `AnalyticsService.flush()` after tracking to push the event batch to `POST /events`.
  - Original fields such as `event`, `feature`, and `action` are preserved under `data` in the event payload for downstream analytics.
- Rationale:
  - Avoids split paths where some clicks post a single JSON body and others use batched tracking.
  - Guarantees single-click events appear alongside batched navigation events in the `events` collection.
- Example (contract action):
```json
{
  "action": "apiCall",
  "params": {
    "service": "analytics",
    "endpoint": "trackEvent",
    "event": "item_click",
    "feature": "podcasts",
    "action": "view_podcast"
  }
}
```
This action is now transformed into a tracked `tap` event with `data.event`, `data.feature`, and `data.action` attributes and flushed immediately.

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

### Attribution Fields
- Client includes the following on each event when `AnalyticsService` is properly wired:
  - `contractType` (`canonical` | `personalized` | `unknown`)
  - `contractVersion` (string)
  - `isPersonalized` (boolean)
  - Top-level `id` (string, 24-hex) when a valid user exists — used by backend attribution
  - Mirrored `data.userId` for downstream analytics segmentation
- Ensure your ingestion pipeline tolerates missing values and uses these fields for segmentation and attribution.

## Testing and Docs
- Run tests: `flutter test`.
- Test logs are recorded in `docs/flutter-test-results.md` (see Run 4 for analytics-related outputs).

## Troubleshooting
- 401 Unauthorized: Configure your backend to accept unauthenticated analytics or attach required auth headers.
- 401 behavior: client halts flush and clears events that contain `userId`, preventing retry loops.
- Empty URL after env resolution: Ensure `.env` defines `ANALYTICS_BACKEND_URL` with a full URL.
- No button visible: The test button only appears in debug builds (`kDebugMode`).
- Unexpected path `/analytics/events`: verify `.env` or contract `analytics.backendUrl` does not include `/analytics` (the client now coerces it to `/events`). Prefer setting `ANALYTICS_BACKEND_URL=http://localhost:8081/events`.
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
  "id": "507f1f77bcf86cd799439011",
  "timestamp": 1681836102000,
  "componentId": "login_button",
  "eventType": "tap",
  "pageId": "login",
  "pageScope": "public",
  "contractType": "canonical",
  "contractVersion": "1.0.0",
  "isPersonalized": false,
  "userId": "507f1f77bcf86cd799439011"
}
```

## Auth Header and Debug Auto-Login (Updated)
- Analytics endpoints are public. If an access token is available, the client may attach `Authorization: Bearer <JWT>`; this header is optional.
- JWT acquisition follows standard app login. Debug auto-login has been removed.
- Removal rationale:
  - Prevent unintended authentication during development and startup.
  - Align with token-only gating (protected routes require a non-empty `authToken`, not `state.user.id`).
- Impact:
  - Manual login is required to obtain a token; analytics continue to ingest without authentication.
  - No `.env` keys for debug auto-login are honored anymore (`DEBUG_AUTO_LOGIN`, `DEBUG_EMAIL`, `DEBUG_PASSWORD`).

## Startup Baseline Flush (debug-only)
- In debug builds, the app flushes a small baseline after a short delay (2 seconds) post-startup.
- Purpose: Allow initial page view events (e.g., landing page) to be tracked and then pushed to the backend for quick verification.
- This baseline flush only includes public-scope events and is skipped in release builds.

### Public Analytics Endpoints: End-to-End Checklist
- Start backend with MongoDB configured (`MONGO_URL` in NestJS `.env`).
- Ensure seeding is enabled (optional) to create the debug user.
- Verify login route: `POST /auth/login` with body `{ email, password }` returns `accessToken`.
- Confirm Flutter `.env` sets `API_BASE_URL=http://localhost:8081`.
- Launch the Flutter app (`flutter run`). In logs you should see:
  - No debug auto-login messages (feature removed)
  - `Analytics configured: http://localhost:8081/events`
  - Baseline flush attempts shortly after startup.
- Inspect server logs for `POST /events` (batch) or `POST /events/tracking-event` (single); requests may arrive with or without `Authorization`.

---

## Public Mode — No JWT Required for Event Ingestion or Reads

When running the MVP, the backend accepts analytics events without authentication.

- Backend behavior
  - `POST /events` and `POST /events/tracking-event` are public.
  - If unauthenticated, events are stored under a fallback user id.
  - Aggregation endpoints are public in this refactor.

- Flutter behavior
  - `AnalyticsService.flush()` will include `Authorization` when a token is present, but this is optional.
  - No changes are required in the app; if auto-login is disabled, events still ingest successfully.

- Quick check
  - Launch the app (`flutter run`).
  - Navigate between bottom tabs to trigger immediate flushes.
  - Verify backend logs show `POST /events` without `Authorization`.