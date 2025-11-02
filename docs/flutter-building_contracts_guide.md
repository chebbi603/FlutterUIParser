Project: demo_json_parser (Flutter)
# Building Canonical Contracts — Single Guide

This document is the canonical, single-source guide for authoring, validating, and delivering JSON contracts used by the Flutter app. Follow it when building or modifying contracts.

## Quick Start
- Author your contract JSON under `assets/contracts/` (e.g., `assets/contracts/canonical-contract.json`).
- Run `flutter test` to validate parsing, schema assumptions, and integration tests.
- Launch the app with `flutter run` (opens the iOS simulator) to visually verify pages.
- Backend delivery (optional): expose the contract via an API; the app can fetch and apply it at runtime.

## Contract Structure (Top-Level Keys)
- `meta`: app name, versions, generatedAt, authors, compatibility.
- `dataModels`: models with `fields`, `relationships`, `indexes`.
- `services`: `baseUrl`, `endpoints` with `path`, `method`, `auth`, `queryParams`, `requestSchema`, `responseSchema`, `caching`, `retryPolicy`.
- `pagesUI`: `routes`, `bottomNavigation`, and `pages` with component trees.
- `state`: `global` and page-level state fields, persistence policies.
- `eventsActions`: declarative actions and event-driven flows.
- `themingAccessibility`: tokens, typography, default theme, accessibility.
- `assets`: images/fonts references.
- `validations`: reusable validation rules and messages.
- `permissionsFlags`: feature flags and role-based access.
- `pagination`: defaults for list/data source pagination.
- `analytics` (optional): configuration for event tagging and backend.

## Authoring Data Models
### Fields
- Canonical form (map): `{ "type": "string", "required": true, "minLength": 2 }`
- Supported constraints: `required`, `primaryKey`, `unique`, `default`, `validation`, `minLength`, `maxLength`, `min`/`maximum`, `enum`, `foreignKey`, `schema`, `autoGenerate`, `autoUpdate`.
- Types: `string`, `integer`, `number`, `boolean`, `object`, `array`.
- Synonyms normalized: `int/integer`, `bool/boolean`, `map/object`, `list/array`, `float/double -> number`.

### Relationships
- Canonical: `{ "type": "hasMany", "model": "Post", "foreignKey": "userId" }`.
- Types: `hasOne`, `hasMany`, `belongsTo`, `belongsToMany`.

### Indexes
- Canonical: `{ "fields": ["email"], "unique": true }`.
- Optional `where` for partial indexes.

### Shorthand (Supported)
- Fields in maps: `{ "id": "string" }`.
- Fields list (bare names): `["title", "description"]` -> both `string` fields.
- Fields list (`name:type`): `["priority:string", "rating:number"]`.
- Enum shorthand: a list value for a field is treated as `type=string` with `enum`, e.g., `"status": ["new", "done"]`.
- Relationships list: `["User"]` -> `{ "type": "hasOne", "model": "User" }`.
- Indexes list string: `["unique:id", "status"]`.

## Authoring Services & Endpoints
- Minimal service: `{ "baseUrl": "${API_BASE_URL}/auth", "endpoints": { ... } }`.
- Endpoints:
  - `path`: `/login`, `method`: `GET|POST|PUT|DELETE`.
  - `auth`: `true|false|string` (e.g., a policy name).
  - `queryParams`: map of params with `type`, `default`, `min`, `max`, `minLength`, `enum`.
  - `requestSchema` / `responseSchema`: JSON Schema-like structures.
  - `caching`: `{ "enabled": true, "ttlSeconds": 60 }` or shorthand `true|false|"60"`.
  - `retryPolicy`: `{ "maxAttempts": 3, "backoffMs": 1000 }` or shorthand `"exponential"`.

### Service Name Aliasing
- Parser adds lowercase aliases for service keys ending with `Service` or `Api` (original preserved).
- Examples: `AuthService` -> alias `auth`, `UserApi` -> `user`.

### Endpoint Key Aliasing
- The parser normalizes common endpoint key synonyms to canonical forms:
  - `authRequired` or `requiresAuth` → `auth` (boolean or string policy)
  - `params` → `queryParams`
  - `retry` → `retryPolicy`
- You can use either canonical or aliased keys; the app treats them equivalently.
- Example:
```json
{
  "services": {
    "AnalyticsService": {
      "baseUrl": "${API_BASE_URL}/analytics",
      "endpoints": {
        "track": {
          "path": "/track",
          "method": "POST",
          "authRequired": false,
          "params": { "dryRun": { "type": "boolean", "default": false } },
          "retry": { "maxAttempts": 3, "backoffMs": 500 }
        }
      }
    }
  }
}
```
This is equivalent to using `auth`, `queryParams`, and `retryPolicy` in the endpoint definition.

## Authoring Pages UI
- `routes`: map of route → `{ pageId, auth }`.
- `pages`: each page defines `id`, `title`, `layout`, `children` (components).
- Components (examples): `text`, `button`, `icon`, `form`, `textField`, `switch`, `slider`, `list`, `card`.
- Component actions: `navigate`, `pop`, `openUrl`, `apiCall`, `updateState`, `showError`, `showSuccess`, `submitForm`, `refreshData`, `showBottomSheet`, `showDialog`, `clearCache`.
- Bindings: use `${state.key}` or data binding paths (e.g., list item fields).
- Styles: theme token resolution from `themingAccessibility.tokens`.

## State & Persistence
- Scopes: `global`, `page`, `session`, `memory`.
- Persistence policies: `local` (shared prefs), `secure` (secure storage), `none`.
- Defaults: provide `default` values for state fields where appropriate.

## Validations
- Field-level: `required`, `email`, `minLength`, `maxLength`, `pattern`, and `message`.
- Rule-based: define in `validations.rules` then reference via `validation: "ruleName"`.
- Cross-field: define relational checks in `validations.crossField`.

## End-to-End Workflow
1. Create/modify contract JSON in `assets/contracts/`.
2. Validate structure by running `flutter test`.
3. Launch with `flutter run` to verify pages and behaviors.
4. Optional: serve the contract via backend; configure the app to fetch it.
5. Record test results in `docs/flutter-test-results.md` (see history in `docs/history/`).

## Minimal Example
```json
{
  "meta": { "appName": "My App", "version": "1.0.0" },
  "dataModels": {
    "User": {
      "fields": ["id", "email", "name"],
      "indexes": ["unique:id", "email"]
    }
  },
  "services": {
    "AuthService": {
      "baseUrl": "${API_BASE_URL}/auth",
      "endpoints": {
        "login": {
          "path": "/login",
          "method": "POST",
          "requestSchema": {
            "type": "object",
            "properties": {
              "email": { "type": "string" },
              "password": { "type": "string", "minLength": 8 }
            },
            "required": ["email", "password"]
          }
        }
      }
    }
  },
  "pagesUI": {
    "routes": { "/": { "pageId": "login", "auth": false } },
    "pages": {
      "login": {
        "id": "login",
        "title": "Sign In",
        "layout": "center",
        "children": [
          { "type": "textField", "id": "email", "label": "Email" },
          { "type": "textField", "id": "password", "label": "Password", "obscureText": true },
          { "type": "button", "text": "Sign In", "onTap": { "action": "submitForm", "formId": "loginForm" } }
        ]
      }
    }
  }
}
```

## Common Pitfalls & Tips
- Ensure every `route.pageId` exists under `pages`.
- Use normalized type names; avoid mixing synonyms unnecessarily.
- Keep `auth` consistent between routes and endpoints.
- Provide default values for state where UI depends on them.
- Use validation rules for consistent messages and cross-field checks.

## Commands
- Validate tests: `flutter test`
- Run the app: `flutter run`

## References
- Contract schema (guide-level): `docs/flutter-canonical_framework_guide.md`
- Parser behavior and shorthand: `docs/flutter-framework_implementation_summary.md`
- Test results overview: `docs/flutter-test-results.md` (with `docs/history/`)