Project: demo_json_parser (Flutter)
# Backend ↔ Frontend Communication Guide

This guide describes how the backend communicates with the Flutter frontend in the JSON‑driven framework. It covers the canonical contract delivery, data/API calls, action execution patterns, state updates, error conventions, pagination, authentication, and analytics.

## 1. Canonical Contract Delivery
The frontend renders UI and wiring from a single JSON document (the "canonical contract"). The backend should expose an endpoint that returns the latest contract.

- Endpoint (this repository): `GET /contracts/canonical` (public)
- Alias (public): `GET /contracts/public/canonical` — identical response; provided to avoid dynamic route collisions.
- Client fallback policy: The Flutter client first calls `/contracts/canonical` and, on `401` or `404`, falls back to `/contracts/public/canonical`. If both fail, it loads `assets/canonical_contract.json`.
- Response: Canonical JSON with keys: `meta`, `services`, `pagesUI`, `state`, `eventsActions`, `themingAccessibility`, `assets`, `validations`, `permissionsFlags`, `pagination`, `analytics`.
- Caching: Recommend `ETag` or `If-None-Match` support to avoid unnecessary downloads.
- Versioning: Include `meta.version` and optionally `meta.apiSchemaVersion`.

Example (truncated):
```json
{
  "meta": { "appName": "Demo", "version": "1.0.0" },
  "services": {
    "user": {
      "baseUrl": "https://api.example.com",
      "endpoints": {
        "login": { "method": "POST", "path": "/auth/login" },
        "me":    { "method": "GET",  "path": "/user/me" }
      }
    }
  },
  "pagesUI": { "pages": { /* layout + components */ } },
  "eventsActions": { /* action definitions */ },
  "analytics": { "backendUrl": "https://api.example.com/events", "trackedComponents": ["login_button"] }
}
```

## 2. Service & Endpoint Configuration
The contract defines named `services` and their `endpoints`. The frontend resolves API calls using these names.

- Fields per endpoint: `method` (GET, POST, etc.), `path`, optional `headers`, `queryParams`, `caching`.
- URL building: `baseUrl + path`, with query parameters from action `params` + endpoint defaults.
- Headers: Endpoint headers merged with global headers (e.g., `Authorization`).
- Caching: If enabled in endpoint config, responses may be cached by URL.

Example endpoint config:
```json
"services": {
  "catalog": {
    "baseUrl": "https://api.example.com",
    "endpoints": {
      "listProducts": {
        "method": "GET",
        "path": "/products",
        "queryParams": { "limit": 20 },
        "caching": { "enabled": true, "ttlSeconds": 300 }
      }
    }
  }
}
```

## 3. Action Execution & API Calls
Components define `actions` (e.g., button tap triggers `apiCall`, `navigate`, `updateState`). The frontend uses the action dispatcher to execute them.

- `apiCall`: Uses `service` and `endpoint` names from the contract; merges `params` and `data` (body) with template resolution.
- `submitForm`: Gathers form state into `data` and calls configured endpoint.
- `updateState`: Applies state changes (supports optimistic updates).
- `refreshData`: Re‑fetches configured data lists.

Example action (button):
```json
{
  "type": "button",
  "id": "login_button",
  "label": "Login",
  "onTap": {
    "action": "apiCall",
    "service": "user",
    "endpoint": "login",
    "params": { "loadingKey": "auth.loading" },
    "data": { "email": "${state.form.email}", "password": "${state.form.password}" }
  }
}
```

## 4. Response Shapes & State Binding
The frontend binds UI to JSON keys using `${state.*}` templates and component bindings.

- Lists: Default extraction path is `data` (configurable via `listPath`).
- Pagination: Optional `total` and `page` fields (configurable via `totalPath`, `pagePath`).
- State updates: API responses can be written into state keys declared in the contract.

Recommended list response:
```json
{ "data": [ {"id":1,"name":"A"}, {"id":2,"name":"B"} ], "total": 42, "page": 3 }
```

## 5. Error Conventions
Use a consistent error shape to simplify UI handling and analytics.

- 4xx/5xx responses should include:
```json
{ "error": { "code": "BAD_REQUEST", "message": "Invalid email", "details": { "field": "email" } } }
```
- Frontend shows `message`; `details` may drive validation messages.
- For form submissions, include `error.message` to be linked with analytics events when `result: "fail"`.

## 6. Authentication
Bearer token authentication is supported.

- Login flow: Backend issues an access token (e.g., `POST /auth/login`).
- Frontend sets header: `Authorization: Bearer <token>`.
- Token refresh: Expose `POST /auth/refresh` if needed; contract can define actions to call it.

## 7. Pagination & Filtering
Standardize query parameters for list endpoints.

- Query params: `page`, `limit`, optional filters like `q`, `sort`.
- Response: Include `total` and `page` when available.
- Contract can override extraction paths if backend uses different keys.

## 8. Analytics Events (Client → Backend)
User interactions are tracked client‑side and POSTed in batches.

- Endpoint: `POST /events` (configured via `analytics.backendUrl`).
- Payload: JSON array of event objects.
- Event fields: `timestamp`, `componentId`, `eventType`, optional `tag` (`rage_click` | `rapid_repeat`), optional `repeatCount`.
- Form submit failures: include `result: "fail"` and `error`.

Example payload:
```json
[
  { "timestamp": 1681836102000, "componentId": "login_button", "eventType": "tap" },
  { "timestamp": 1681836102500, "componentId": "login_form", "eventType": "formSubmit", "result": "fail", "error": "Invalid credentials" }
]
```

## 9. Versioning & Compatibility
- Use `meta.version` and `meta.apiSchemaVersion` to track contract/API changes.
- Prefer additive changes; document breaking changes and serve compatible contracts per client version.

## 10. Security & Privacy
- Do not include sensitive fields (e.g., passwords) in analytics.
- Scope state and permissions via contract `permissionsFlags`.
- Use HTTPS for all service endpoints.

## 11. Optional Real‑Time Updates
If live updates are required, define one of:

- Server‑Sent Events: `GET /stream/contract` (push new contract versions).
- WebSocket: `/ws` channel with messages `{ type: "contract:update", payload: { /* contract */ } }`.
- Fallback: Use `refreshData` actions on intervals.

## Document Conventions
- Headings use Title Case.
- Dates use ISO 8601 (`YYYY-MM-DD`).
- Analytics payloads use milliseconds since epoch (`timestamp`).
- Terminology is consistent: `service`, `endpoint`, `componentId`, `eventType`, `backendUrl`.