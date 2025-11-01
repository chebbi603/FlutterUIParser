Project: demo_json_parser (Flutter)
# Analytics Tracking Guide (JSON‑Driven)

## Overview
- Minimal, ID‑based tracking configured from contract JSON.
- No legacy integration classes; tracking is opt‑in by component `id`.
- `EnhancedPageBuilder` wraps matching components with `ComponentTracker`.
- Events accumulate in memory and can be POSTed via `AnalyticsService.flush()`.

## Contract Configuration
Add an `analytics` block to your contract:
```json
{
  "analytics": {
    "backendUrl": "https://your-api.example.com/events",
    "trackedComponents": ["login_button", "email_field", "submit_button"]
  }
}
```

## App Wiring
Configure service and pass tracked IDs when building pages:
```dart
// app.dart
final service = AnalyticsService();
service.configure(backendUrl: contract.analytics?.backendUrl);
// Attach providers to enable contract/auth attribution
service.attachContractProvider(provider);
service.attachStateManager(stateManager);
final trackedIds = contract.analytics?.trackedComponents ?? const [];

return EnhancedPageBuilder(
  config: pageConfig,
  trackedIds: trackedIds,
);
```

## Component Tracking
`EnhancedPageBuilder` automatically wraps components whose `config.id` is in `trackedIds`:
```dart
ComponentTracker(
  componentId: 'login_button',
  componentType: 'button',
  pageId: 'login',
  child: CupertinoButton(onPressed: onLogin, child: Text('Login')),
)
```
You can also wrap widgets explicitly with `ComponentTracker` when needed.

## Events and Types
Tracked interactions create `TrackingEvent` objects with fields:
- `id`, `type`, `timestamp`, `sessionId`
- `componentId`, `componentType`, `pageId`
- `data`, `context`, `duration`, `errorMessage`

Page navigation can be tracked via:
```dart
AnalyticsService().trackPageNavigation(pageId: 'login', eventType: TrackingEventType.pageEnter);
```

## Document Conventions
- Headings use Title Case.
- Timestamps: docs use ISO 8601 dates; analytics payloads use milliseconds since epoch.
- Consistent terminology: `trackedComponents`, `componentId`, `eventType`, `backendUrl`.
- Code and JSON examples are illustrative; adapt to your environment.

## Event Formatting and Timestamps
- Flush posts a JSON array, one object per event.
- `timestamp` is in milliseconds since epoch.
- Required: `timestamp`, `componentId`, `eventType`.
- Optional: `tag` (`rage_click` | `rapid_repeat`), `repeatCount`.
- For `formSubmit`: include `result` (`success` | `fail`) and optional `error`.

### Attribution Metadata (added)
- `contractType`: `canonical` or `personalized` (string; default `unknown`)
- `contractVersion`: semantic version from contract (string; default `unknown`)
- `isPersonalized`: whether the active contract is personalized (boolean)
- `userId`: current user id from `EnhancedStateManager.getGlobalState('user').id` (string or null)

Notes:
- Metadata is added at formatting time inside `AnalyticsService.flush()` and is not mutating `TrackingEvent.data`.
- Ensure `AnalyticsService.attachContractProvider()` and `.attachStateManager()` are called before tracking/flush to populate these fields.

Example:
```json
[
  { "timestamp": 1681836102000, "componentId": "login_button", "eventType": "tap" },
  { "timestamp": 1681836102500, "componentId": "login_form", "eventType": "formSubmit", "result": "fail", "error": "Invalid credentials" }
]
```

## Sending to Backend
- Configure `backendUrl` in the contract.
- Manually send accumulated events in one batch:
```dart
await AnalyticsService().flush();
```
If no `backendUrl` is set, events remain in memory and are printed in debug builds.

### Flush Behavior (updated)
- Missing `backendUrl`: logs a warning and keeps events queued.
- 2xx responses: removes successfully sent events from memory.
- `401 Unauthorized`: stops flush; if any event has `userId`, clears the in-memory queue to prevent retry storms.
- Validation: warns when events are missing `contractType`, `contractVersion`, or `isPersonalized` (ensure attachments).

## FAQs
- Where do events go?
  - In debug: printed to console. With `backendUrl`: sent on `flush()`.
- How do I add tracking?
  - Provide explicit `id` values in your contract and include them in `trackedComponents`, or wrap widgets with `ComponentTracker`.
- How do I disable tracking?
  - Omit the component `id` from `trackedComponents`, or set `enabled: false` on `ComponentTracker`.

## Migration Notes
Removed: `AnalyticsAppIntegration`, `TrackedComponentFactory`, session summaries, buffering middleware, connectivity/offline queue. Use JSON‑driven `trackedComponents` + `ComponentTracker` and `AnalyticsService.flush()` instead.
## Page Scope Classification (added)
- Field: `pageScope` indicates if the page is `public` or `authenticated`.
- Computation:
  - If the active contract defines `pagesUI.routes[<route>].auth`, then `true` → `authenticated`, `false` → `public`.
  - If `EnhancedBottomNavigationConfig.authRequired` is set for the active tab, it overrides to `authenticated`.
  - Fallback heuristics: known pages `login`, `signup`, `forgotPassword` are treated as `public`; unknown pages default to `authenticated`.
- Wiring:
  - Ensure `AnalyticsService.attachContractProvider()` is called so routes are available.
  - Provide `pageId` when tracking navigation or component interactions; `EnhancedPageBuilder` does this automatically.
- Backend:
  - `pageScope` is included in the formatted payload during `flush()` alongside attribution metadata.

Example event (enriched):
```json
{
  "timestamp": 1681836102000,
  "componentId": "login_button",
  "eventType": "tap",
  "pageId": "login",
  "pageScope": "public",
  "contractType": "canonical",
  "contractVersion": "1.0.0",
  "isPersonalized": false
}
```

Implementation notes:
- `AnalyticsService.track()` and `trackComponentInteraction()` compute `pageScope` from the attached contract provider and known page IDs.
- `EnhancedPageBuilder` passes `pageId` to trackers; ensure page IDs match `pagesUI.pages` keys in the contract.
- If `pageScope` cannot be inferred, it defaults to `authenticated` to avoid under‑scoping.