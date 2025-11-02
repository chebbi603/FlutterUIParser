Project: demo_json_parser (Flutter)
# Analytics Backend Integration (Flush‑Based)

This document explains how tracked events are sent to a backend API using the simplified, flush‑based workflow.

## Overview

- Events are collected in memory by `AnalyticsService`.
- Configure a `backendUrl` (from contract JSON) and call `flush()` to POST events.
- No offline queue or connectivity monitoring is included.

## Configure Backend URL

Set the URL during app startup using the contract:

```dart
final service = AnalyticsService();
service.configure(backendUrl: contract.analytics?.backendUrl);
```

Contract snippet:

```json
{
  "analytics": {
    "backendUrl": "https://your-api.example.com/events"
  }
}
```

## Send Events

Trigger a batch POST of all accumulated events:

```dart
await AnalyticsService().flush();
```

Behavior:

- If `backendUrl` is unset/empty, a debug warning is printed and events remain in memory.
- On 2xx response, events are cleared.
- On non‑2xx or error, events are retained for later flushes.

## HTTP Contract (NestJS DTO Compatible)

Request:

- Method: `POST`
- URL: `backendUrl` (typically `/events`)
- Headers: `Content-Type: application/json`
- Body:

```json
{
  "events": [
    {
      "timestamp": "2025-11-02T15:35:00.000Z",
      "componentId": "login_button",
      "eventType": "tap",
      "page": "auth",
      "data": {
        "pageScope": "public",
        "contractType": "canonical",
        "contractVersion": "v1",
        "isPersonalized": false
      }
    },
    {
      "timestamp": "2025-11-02T15:35:02.000Z",
      "componentId": "login_form",
      "eventType": "input",
      "page": "auth",
      "data": {
        "pageScope": "public",
        "result": "fail",
        "error": "Invalid credentials",
        "tag": "rapid_repeat",
        "repeatCount": 3
      }
    }
  ]
}
```

### Event DTO Fields

- `timestamp`: ISO 8601 date-time string
- `componentId`: string (required)
- `eventType`: one of `tap | view | input | navigate | error | form-fail`
- `page`: optional page identifier
- `sessionId`: optional string (only set when it is a valid 24-hex ObjectId)
- `data`: optional object containing metadata and tags

### Event Type Mapping

- Interactions: `tap` → `tap`; `scroll|swipe|componentRender|apiCall` → `view`
- Inputs: `focus|blur|input|stateChange|formSubmit` → `input`
- Navigation: `pageEnter|pageExit|routeChange|networkChange|appBackground|appForeground` → `navigate`
- Errors: `validationError|error` → `error`

### Client-Side Tagging

- Rage clicks: 3+ identical taps to the same `componentId` within 1s → tag `rage_click`.
- Rapid repeats: same action repeated ≥N times in a short window (default N=3, 2s; `formSubmit` uses 10s) → tag `rapid_repeat`.
- Failed form submissions: set `result: "fail"` and include `error` when available.

### Configurability

```dart
AnalyticsService().updateTaggingConfig(
  rageThreshold: 3,
  rageWindowMs: 1000,
  repeatThreshold: 3,
  repeatWindowMs: 2000,
  formRepeatWindowMs: 10000,
  formFailWindowMs: 10000,
);
```

## Typical Integration Flow

- Add `trackedComponents` to your contract to enable wrapping.
- Interact with the app; events accumulate in memory.
- Call `flush()` (e.g., on page exit, user action, or a timed trigger) to send.

## Troubleshooting

- No events sent: confirm `backendUrl` is configured and reachable.
- Empty payload: check `AnalyticsService().events.length`.
- Backend error: inspect status code and response; events are kept for retry.

## Notes

- Advanced features (connectivity, offline queue, metrics endpoints) were removed.
- Extend `AnalyticsService` if you need retries, batching intervals, or richer telemetry.

## Document Conventions

- Headings use Title Case across sections.
- Timestamps: payloads use ISO 8601 date-time strings.
- Terminology: `componentId`, `eventType`, `backendUrl` are used consistently.
- Code and JSON examples are illustrative; adapt URLs and IDs to your environment.
