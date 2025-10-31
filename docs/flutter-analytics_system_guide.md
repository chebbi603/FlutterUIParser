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

## FAQs
- Where do events go?
  - In debug: printed to console. With `backendUrl`: sent on `flush()`.
- How do I add tracking?
  - Provide explicit `id` values in your contract and include them in `trackedComponents`, or wrap widgets with `ComponentTracker`.
- How do I disable tracking?
  - Omit the component `id` from `trackedComponents`, or set `enabled: false` on `ComponentTracker`.

## Migration Notes
Removed: `AnalyticsAppIntegration`, `TrackedComponentFactory`, session summaries, buffering middleware, connectivity/offline queue. Use JSON‑driven `trackedComponents` + `ComponentTracker` and `AnalyticsService.flush()` instead.